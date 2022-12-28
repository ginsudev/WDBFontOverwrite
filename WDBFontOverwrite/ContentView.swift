//
//  ContentView.swift
//  WDBFontOverwrite
//
//  Created by Zhuowei Zhang on 2022-12-25.
//

import SwiftUI

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
}

let customFonts = [
  CustomFont(
    name: "SFUI.ttf", targetPath: "/System/Library/Fonts/CoreUI/SFUI.ttf",
    localPath: "CustomSFUI.woff2"),
  CustomFont(
    name: "Emoji", targetPath: "/System/Library/Fonts/CoreAddition/AppleColorEmoji-160px.ttc",
    localPath: "CustomAppleColorEmoji.woff2"),
  CustomFont(
    name: "PingFang.ttc", targetPath: "/System/Library/Fonts/LanguageSupport/PingFang.ttc",
    localPath: "CustomPingFang.woff2"),
]

struct ContentView: View {
  @State private var message = "Choose a font."
  @State private var progress: Progress!
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
            }
          }) {
            Text("Custom \(font.name)")
          }.padding(8)
          Button(action: {
            message = "Importing..."
            importCustomFont(name: font.localPath) {
              message = $0
            }
          }) {
            Text("Import custom \(font.name)")
          }.padding(8)
        }
      }
      Text(
        "Custom fonts require font files that are ported for iOS.\nSee https://github.com/zhuowei/WDBFontOverwrite for details."
      ).font(.system(size: 12))
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
