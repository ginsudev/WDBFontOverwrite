//
//  ContentView.ViewModel.swift
//  WDBFontOverwrite
//
//  Created by Noah Little (@ginsudev) on 31/12/2022.
//

import Foundation

enum PathType {
    case single(String)
    case many([String])
}

struct CustomFont {
    var name: String
    var targetPath: PathType?
    var localPath: String
    var alternativeTTCRepackMode: TTCRepackMode?
    var notice: Notice?
}

struct FontToReplace {
    var name: String
    var postScriptName: String
    var repackedPath: String
}

enum CustomFontType: String {
    case font = "fonts"
    case emoji = "emojis"
}

extension ContentView {
    final class ViewModel: ObservableObject {
        @Published var fontListSelection: Int = 0
        @Published var customFontPickerSelection: Int = 0
        @Published var message = "Choose a font."
        @Published var importPresented: Bool = false
        @Published var isPresentedFileEditor: Bool = false
        @Published var isPresentedFontDiscovery: Bool = false
        @Published var importTTCRepackMode: TTCRepackMode = .woff2
        @Published var allowsMultipleSelection: Bool = true
        @Published var importType: CustomFontType = .font
        
        var selectedCustomFontType: CustomFontType {
            return customFontPickerSelection == 0 ? .font : .emoji
        }
        
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
        
        func batchOverwriteFonts() async {
            guard selectedCustomFontType == .font else {
                // Overwrite emoji
                let emojiFont = FontMap.emojiCustomFont
                await overwriteWithCustomFont(
                    name: emojiFont.localPath,
                    targetPath: emojiFont.targetPath
                ) {
                    self.message = $0
                }
                ProgressManager.shared.isBusy = false
                return
            }
            
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]
            do {
                let fonts = try fileManager.contentsOfDirectory(atPath: documentsDirectory.relativePath).filter({!$0.contains("AppleColorEmoji")})
                for font in fonts {
                    let key = FontMap.key(forFont: font)
                    if let customFont = FontMap.fontMap[key] {
                        await overwriteWithCustomFont(
                            name: customFont.localPath,
                            targetPath: customFont.targetPath
                        ) {
                            self.message = $0
                        }
                    }
                }
                ProgressManager.shared.isBusy = false
            } catch  {
                print(error)
                message = "Failed to read imported fonts."
            }
        }
    }
}
