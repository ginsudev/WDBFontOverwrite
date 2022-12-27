//
//  OverwriteFontImpl.swift
//  WDBFontOverwrite
//
//  Created by Zhuowei Zhang on 2022-12-25.
//

import UIKit
import UniformTypeIdentifiers

func overwriteWithFont(name: String, completion: @escaping (String) -> Void) {
  DispatchQueue.global(qos: .userInteractive).async {
    let fontURL = Bundle.main.url(
      forResource: name, withExtension: nil, subdirectory: "RepackedFonts")!
    let succeeded = overwriteWithFontImpl(fontURL: fontURL)
    DispatchQueue.main.async {
      completion(succeeded ? "Success: force close an app to see results" : "Failed")
    }
  }
}

/// Overwrite the system font with the given font using CVE-2022-46689.
/// The font must be specially prepared so that it skips past the last byte in every 16KB page.
/// See BrotliPadding.swift for an implementation that adds this padding to WOFF2 fonts.
func overwriteWithFontImpl(fontURL: URL) -> Bool {
  var fontData = try! Data(contentsOf: fontURL)
  let pathToTargetFont = "/System/Library/Fonts/CoreUI/SFUI.ttf"
  #if false
    let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[
      0
    ].path
    let pathToTargetFont = documentDirectory + "/SFUI.ttf"
    let pathToRealTargetFont = "/System/Library/Fonts/CoreUI/SFUI.ttf"
    let origData = try! Data(contentsOf: URL(fileURLWithPath: pathToRealTargetFont))
    try! origData.write(to: URL(fileURLWithPath: pathToTargetFont))
  #endif

  // open and map original font
  let fd = open(pathToTargetFont, O_RDONLY | O_CLOEXEC)
  if fd == -1 {
    print("can't open font?!")
    return false
  }
  defer { close(fd) }
  // check size of font
  let originalFontSize = lseek(fd, 0, SEEK_END)
  guard originalFontSize >= fontData.count else {
    print("font too big!")
    return false
  }
  lseek(fd, 0, SEEK_SET)

  // patch our font with the padding
  // https://www.w3.org/TR/WOFF2/#woff20Header
  // length
  withUnsafeBytes(of: UInt32(originalFontSize).bigEndian) {
    fontData.replaceSubrange(0x8..<0x8 + 4, with: $0)
  }
  // privOffset
  withUnsafeBytes(of: UInt32(fontData.count).bigEndian) {
    fontData.replaceSubrange(0x28..<0x28 + 4, with: $0)
  }
  // privLength
  withUnsafeBytes(of: UInt32(Int(originalFontSize) - fontData.count).bigEndian) {
    fontData.replaceSubrange(0x2c..<0x2c + 4, with: $0)
  }

  // Map the font we want to overwrite so we can mlock it
  let fontMap = mmap(nil, fontData.count, PROT_READ, MAP_SHARED, fd, 0)
  if fontMap == MAP_FAILED {
    print("map failed")
    return false
  }
  // mlock so the file gets cached in memory
  guard mlock(fontMap, fontData.count) == 0 else {
    print("can't mlock")
    return false
  }

  // for every 16k chunk, rewrite
  for chunkOff in stride(from: 0, to: fontData.count, by: 0x4000) {
    // we only rewrite 16383 bytes out of every 16384 bytes.
    let dataChunk = fontData[chunkOff..<min(fontData.count, chunkOff + 0x3fff)]
    var overwroteOne = false
    for _ in 0..<2 {
      let overwriteSucceeded = dataChunk.withUnsafeBytes { dataChunkBytes in
        return unaligned_copy_switch_race(
          fd, Int64(chunkOff), dataChunkBytes.baseAddress, dataChunkBytes.count)
      }
      if overwriteSucceeded {
        overwroteOne = true
        break
      }
      print("try again?!")
      sleep(1)
    }
    guard overwroteOne else {
      print("can't overwrite")
      return false
    }
  }
  print("successfully overwrote everything")
  return true
}

func dumpCurrentFont() {
  let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[
    0
  ].path
  let pathToTargetFont = documentDirectory + "/SFUI_dump.ttf"
  let pathToRealTargetFont = "/System/Library/Fonts/CoreUI/SFUI.ttf"
  let origData = try! Data(contentsOf: URL(fileURLWithPath: pathToRealTargetFont))
  try! origData.write(to: URL(fileURLWithPath: pathToTargetFont))
}

func overwriteWithCustomFont(name: String, completion: @escaping (String) -> Void) {
  let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[
    0
  ]
  let fontURL = documentDirectory.appendingPathComponent(name)
  guard FileManager.default.fileExists(atPath: fontURL.path) else {
    completion("No custom font imported")
    return
  }
  DispatchQueue.global(qos: .userInteractive).async {
    let succeeded = overwriteWithFontImpl(fontURL: fontURL)
    DispatchQueue.main.async {
      completion(succeeded ? "Success: force close an app to see results" : "Failed")
    }
  }
}

class WDBImportCustomFontPickerViewControllerDelegate: NSObject, UIDocumentPickerDelegate {
  let completion: ([URL]?) -> Void
  init(completion: @escaping ([URL]?) -> Void) {
    self.completion = completion
  }
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL])
  {
    completion(urls)
  }
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    completion(nil)
  }
}

var globalDelegate: WDBImportCustomFontPickerViewControllerDelegate?

func importCustomFont(name: String, completion: @escaping (String) -> Void) {
  // yes I should use a real SwiftUI way to this, but #yolo
  let pickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: [
    UTType("public.truetype-ttf-font")!, UTType(filenameExtension: "woff2", conformingTo: .font)!,
  ])
  let delegate = WDBImportCustomFontPickerViewControllerDelegate { urls in
    globalDelegate = nil
    guard let urls = urls else {
      completion("Cancelled")
      return
    }
    guard urls.count == 1 else {
      completion("import one file at a time")
      return
    }
    DispatchQueue.global(qos: .userInteractive).async {
      let fileURL = urls[0]
      guard fileURL.startAccessingSecurityScopedResource() else {
        DispatchQueue.main.async {
          completion("startAccessingSecurityScopedResource false?")
        }
        return
      }
      let documentDirectory = FileManager.default.urls(
        for: .documentDirectory, in: .userDomainMask)[
          0
        ]
      let targetURL = documentDirectory.appendingPathComponent(name)
      let success = importCustomFontImpl(fileURL: fileURL, targetURL: targetURL)
      fileURL.stopAccessingSecurityScopedResource()
      DispatchQueue.main.async {
        completion(success ?? "Imported")
      }
    }
  }
  pickerViewController.delegate = delegate
  // I said this is yolo
  globalDelegate = delegate
  (UIApplication.shared.connectedScenes.first! as! UIWindowScene).windows[0].rootViewController!
    .present(pickerViewController, animated: true)
}

func importCustomFontImpl(fileURL: URL, targetURL: URL) -> String? {
  // read first 16k of font
  let fileHandle = try! FileHandle(forReadingFrom: fileURL)
  defer { fileHandle.closeFile() }
  let first16k = try! fileHandle.read(upToCount: 0x4000)!
  if first16k.count == 0x4000 && first16k[0..<4] == Data([0x77, 0x4f, 0x46, 0x32])
    && first16k[0x3fff] == 0x41
  {
    print("already padded WOFF2")
    try! FileManager.default.copyItem(at: fileURL, to: targetURL)
    return nil
  }
  try! fileHandle.seek(toOffset: 0)
  let fileData = try! fileHandle.readToEnd()!
  guard let repackedData = repackTrueTypeFontAsPaddedWoff2(input: fileData) else {
    return "Failed to repack"
  }
  try! repackedData.write(to: targetURL)
  return nil
}

func repackTrueTypeFontAsPaddedWoff2(input: Data) -> Data? {
  var outputBuffer = [UInt8](repeating: 0, count: input.count + 1024)
  var outputLength = outputBuffer.count
  let woff2Result = outputBuffer.withUnsafeMutableBytes {
    WOFF2WrapperConvertTTFToWOFF2([UInt8](input), input.count, $0.baseAddress, &outputLength)
  }
  guard woff2Result else {
    print("woff2 convert failed")
    return nil
  }
  let woff2Data = Data(bytes: outputBuffer, count: outputLength)
  do {
    return try repackWoff2Font(input: woff2Data)
  } catch {
    print("error: \(error).")
    return nil
  }
}

// Hack: fake Brotli compress method that just returns the original uncompressed data.'
// (We're recompressing it anyways in a second!)
@_cdecl("BrotliEncoderCompress")
func fakeBrotliEncoderCompress(
  quality: Int, lgwin: Int, mode: Int, inputSize: size_t, inputBuffer: UnsafePointer<UInt8>,
  encodedSize: UnsafeMutablePointer<size_t>, encodedBuffer: UnsafeMutablePointer<UInt8>
) -> Int {
  let encodedSizeIn = encodedSize.pointee
  if inputSize > encodedSizeIn {
    return 0
  }
  UnsafeBufferPointer(start: inputBuffer, count: inputSize).copyBytes(
    to: UnsafeMutableRawBufferPointer(start: encodedBuffer, count: encodedSizeIn))
  encodedSize[0] = inputSize
  return 1
}
