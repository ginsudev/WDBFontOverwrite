//
//  ContentView.swift
//  WDBFontOverwrite
//
//  Created by Zhuowei Zhang on 2022-12-25.
//

import SwiftUI
import UniformTypeIdentifiers

struct FontToReplace {
  var name: String
  var postScriptName: String
  var repackedPath: String
}

let fonts = [
  FontToReplace(
    name: "DejaVu Sans Condensed", postScriptName: "DejaVuSansCondensed",
    repackedPath: "DejaVuSansCondensed.woff2"),
  FontToReplace(
    name: "DejaVu Serif", postScriptName: "DejaVuSerif", repackedPath: "DejaVuSerif.woff2"),
  FontToReplace(
    name: "DejaVu Sans Mono", postScriptName: "DejaVuSansMono", repackedPath: "DejaVuSansMono.woff2"
  ),
  FontToReplace(name: "Go Regular", postScriptName: "GoRegular", repackedPath: "Go-Regular.woff2"),
  FontToReplace(name: "Go Mono", postScriptName: "GoMono", repackedPath: "Go-Mono.woff2"),
  FontToReplace(
    name: "Fira Sans", postScriptName: "FiraSans-Regular",
    repackedPath: "FiraSans-Regular.2048.woff2"),
  FontToReplace(name: "Segoe UI", postScriptName: "SegoeUI", repackedPath: "segoeui.woff2"),
  FontToReplace(
    name: "Comic Sans MS", postScriptName: "ComicSansMS", repackedPath: "Comic Sans MS.woff2"),
  FontToReplace(
    name: "Choco Cooky", postScriptName: "Chococooky", repackedPath: "Chococooky.woff2"),
]

struct CustomFont {
  var name: String
  var targetPath: String
  var localPath: String
  var alternativeTTCRepackMode: TTCRepackMode
}

let customFonts = [
  CustomFont(
    name: "SFUI.ttf", targetPath: "/System/Library/Fonts/CoreUI/SFUI.ttf",
    localPath: "CustomSFUI.woff2", alternativeTTCRepackMode: .ttcpad),
  CustomFont(
    name: "Emoji", targetPath: "/System/Library/Fonts/CoreAddition/AppleColorEmoji-160px.ttc",
    localPath: "CustomAppleColorEmoji.woff2", alternativeTTCRepackMode: .firstFontOnly),
  CustomFont(
    name: "PingFang.ttc", targetPath: "/System/Library/Fonts/LanguageSupport/PingFang.ttc",
    localPath: "CustomPingFang.woff2", alternativeTTCRepackMode: .ttcpad),
]

struct ContentView: View {
  @State private var message = "Choose a font."
  @State private var progress: Progress!
  @State private var importPresented: Bool = false
  @State private var importName: String = ""
  @State private var importTTCRepackMode: TTCRepackMode = .woff2
  var body: some View {
    ScrollView {
      VStack {
        Text(message).padding(8)
        if let progress = progress {
          ProgressView(progress)
        }
        ForEach(fonts, id: \.name) { font in
          Button(action: {
            message = "Running"
            progress = Progress(totalUnitCount: 1)
            overwriteWithFont(name: font.repackedPath, progress: progress) {
              message = $0
              progress = nil
            }
          }) {
            Text(font.name).font(.custom(font.postScriptName, size: 18))
          }.padding(8)
        }
        Divider()
        ForEach(customFonts, id: \.name) { font in
          Button(action: {
            message = "Running"
            progress = Progress(totalUnitCount: 1)
            overwriteWithCustomFont(
              name: font.localPath, targetName: font.targetPath, progress: progress
            ) {
              message = $0
              progress = nil
            }
          }) {
            Text("Custom \(font.name)")
          }.padding(8)
          Button(action: {
            message = "Importing..."
            importName = font.localPath
            importTTCRepackMode = .woff2
            importPresented = true
          }) {
            Text("Import custom \(font.name)")
          }.padding(8)
          Button(action: {
            message = "Importing..."
            importName = font.localPath
            importTTCRepackMode = font.alternativeTTCRepackMode
            importPresented = true
          }) {
            Text("Import custom \(font.name) with fix for .ttc")
          }.padding(8)
          Divider()
        }
          Button(action: {
              let sharedApplication = UIApplication.shared
              let windows = sharedApplication.windows
              if let window = windows.first {
                  while true {
                      window.snapshotView(afterScreenUpdates: false)
                  }
              }
          }) {
              Text("Respring")
          }.padding(8)

      }
      Text(
        "Custom fonts require font files that are ported for iOS.\nSee https://github.com/zhuowei/WDBFontOverwrite for details."
      ).font(.system(size: 12))
    }
    .sheet(isPresented: $importPresented) {
      DocumentPicker(name: importName, ttcRepackMode: importTTCRepackMode) {
        message = $0
      }
    }
  }
}

class WDBImportCustomFontPickerViewControllerDelegate: NSObject, UIDocumentPickerDelegate {
  let name: String
  let ttcRepackMode: TTCRepackMode
  let completion: (String) -> Void
  init(name: String, ttcRepackMode: TTCRepackMode, completion: @escaping (String) -> Void) {
    self.name = name
    self.ttcRepackMode = ttcRepackMode
    self.completion = completion
  }
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL])
  {
    guard urls.count == 1 else {
      completion("import one file at a time")
      return
    }
    DispatchQueue.global(qos: .userInteractive).async {
      let fileURL = urls[0]
      let documentDirectory = FileManager.default.urls(
        for: .documentDirectory, in: .userDomainMask)[0]
      let targetURL = documentDirectory.appendingPathComponent(self.name)
      let success = importCustomFontImpl(
        fileURL: fileURL, targetURL: targetURL, ttcRepackMode: self.ttcRepackMode)
      DispatchQueue.main.async {
        self.completion(success ?? "Imported")
      }
    }
  }
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    completion("Cancelled")
  }
}

// https://capps.tech/blog/read-files-with-documentpicker-in-swiftui
struct DocumentPicker: UIViewControllerRepresentable {
  let controllerDelegate: WDBImportCustomFontPickerViewControllerDelegate
  init(name: String, ttcRepackMode: TTCRepackMode, completion: @escaping (String) -> Void) {
    controllerDelegate = WDBImportCustomFontPickerViewControllerDelegate(
      name: name, ttcRepackMode: ttcRepackMode, completion: completion)
  }
  func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
    print("make ui view controller?")
    let pickerViewController = UIDocumentPickerViewController(
      forOpeningContentTypes: [
        UTType.font, UTType(filenameExtension: "woff2", conformingTo: .font)!,
      ], asCopy: true)
    pickerViewController.delegate = self.controllerDelegate
    return pickerViewController
  }
  func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context)
  {}
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
