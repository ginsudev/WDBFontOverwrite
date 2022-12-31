//
//  ContentView.ViewModel.swift
//  WDBFontOverwrite
//
//  Created by Noah Little (@ginsudev) on 31/12/2022.
//

import Foundation

extension ContentView {
    struct FontToReplace {
      var name: String
      var postScriptName: String
      var repackedPath: String
    }
    
    struct CustomFont {
      var name: String
      var targetPath: String?
      var targetPaths: [String]?
      var localPath: String
      var alternativeTTCRepackMode: TTCRepackMode
    }
    
    final class ViewModel: ObservableObject {
        @Published var message = "Choose a font."
        @Published var progress: Progress!
        @Published var importPresented: Bool = false
        @Published var importName: String = ""
        @Published var importTTCRepackMode: TTCRepackMode = .woff2
        
        let fonts = [
            FontToReplace(
                name: "DejaVu Sans Condensed",
                postScriptName: "DejaVuSansCondensed",
                repackedPath: "DejaVuSansCondensed.woff2"
            ),
            FontToReplace(
                name: "DejaVu Serif",
                postScriptName: "DejaVuSerif",
                repackedPath: "DejaVuSerif.woff2"
            ),
            FontToReplace(
                name: "DejaVu Sans Mono",
                postScriptName: "DejaVuSansMono",
                repackedPath: "DejaVuSansMono.woff2"
            ),
            FontToReplace(
                name: "Go Regular",
                postScriptName: "GoRegular",
                repackedPath: "Go-Regular.woff2"
            ),
            FontToReplace(
                name: "Go Mono",
                postScriptName: "GoMono",
                repackedPath: "Go-Mono.woff2"
            ),
            FontToReplace(
                name: "Fira Sans",
                postScriptName: "FiraSans-Regular",
                repackedPath: "FiraSans-Regular.2048.woff2"
            ),
            FontToReplace(
                name: "Segoe UI",
                postScriptName: "SegoeUI",
                repackedPath: "segoeui.woff2"
            ),
            FontToReplace(
                name: "Comic Sans MS",
                postScriptName: "ComicSansMS",
                repackedPath: "Comic Sans MS.woff2"
            ),
            FontToReplace(
                name: "Choco Cooky",
                postScriptName: "Chococooky",
                repackedPath: "Chococooky.woff2"
            ),
        ]

        let customFonts = [
            CustomFont(
                name: "SFUI.ttf",
                targetPath: "/System/Library/Fonts/CoreUI/SFUI.ttf",
                localPath: "CustomSFUI.woff2",
                alternativeTTCRepackMode: .ttcpad
            ),
            CustomFont(
                name: "Emoji",
                targetPaths: [
                    "/System/Library/Fonts/CoreAddition/AppleColorEmoji-160px.ttc",
                    "/System/Library/Fonts/Core/AppleColorEmoji.ttc",
                ],
                localPath: "CustomAppleColorEmoji.woff2",
                alternativeTTCRepackMode: .firstFontOnly
            ),
            CustomFont(
                name: "PingFang.ttc",
                targetPath: "/System/Library/Fonts/LanguageSupport/PingFang.ttc",
                localPath: "CustomPingFang.woff2",
                alternativeTTCRepackMode: .ttcpad
            ),
        ]
    }
}
