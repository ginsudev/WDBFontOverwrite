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

enum Notice: String {
    case iosVersion = "iOS version not supported. Don't ask us to support newer versions because the exploit used just simply does not support newer iOS versions."
    case beforeUse = "Custom fonts require font files that are ported for iOS. See https://github.com/ginsudev/WDBFontOverwrite for details."
    case keyboard = "Keyboard fonts may not be applied immediately due to iOS caching issues. IF POSSIBLE, remove the folder /var/mobile/Library/Caches/com.apple.keyboards/ if you wish for changes to take effect immediately."
}

extension ContentView {
    struct FontToReplace {
        var name: String
        var postScriptName: String
        var repackedPath: String
    }
    
    struct CustomFont {
        var name: String
        var targetPath: PathType?
        var localPath: String
        var alternativeTTCRepackMode: TTCRepackMode?
        var notice: Notice?
    }
    
    final class ViewModel: ObservableObject {
        @Published var fontListSelection: Int = 0
        @Published var customFontPickerSelection: Int = 0
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

        let specialCustomFonts = [
            CustomFont(
                name: "Emoji",
                targetPath: .many([
                    "/System/Library/Fonts/CoreAddition/AppleColorEmoji-160px.ttc",
                    "/System/Library/Fonts/Core/AppleColorEmoji.ttc",
                ]),
                localPath: "CustomAppleColorEmoji.woff2"
            )
        ]
        
        var customFontMap = [String: CustomFont]()
        
        func populateFontMap() async {
            let fm = FileManager.default
            let fontDirPath = "/System/Library/Fonts/"
            
            do {
                let fontSubDirectories = try fm.contentsOfDirectory(atPath: fontDirPath)
                for dir in fontSubDirectories {
                    let fontFiles = try fm.contentsOfDirectory(atPath: "\(fontDirPath)\(dir)")
                    for font in fontFiles {
                        guard !font.contains("AppleColorEmoji") else {
                            continue
                        }
                        guard let validatedLocalPath = validateFont(name: font) else {
                            continue
                        }
                        customFontMap[font] = CustomFont(
                            name: font,
                            targetPath: .single("\(fontDirPath)\(dir)/\(font)"),
                            localPath: "Custom\(validatedLocalPath)",
                            alternativeTTCRepackMode: .ttcpad,
                            notice: notice(forFont: font)
                        )
                    }
                }
            } catch {
                print(error)
            }
            
            print(customFontMap)
        }
        
        private func validateFont(name: String) -> String? {
            var components = name.components(separatedBy: ".")
            guard components.last == "ttc" || components.last == "ttf" else {
                return nil
            }
            components[components.count - 1] = "woff2"
            return components.joined(separator: ".")
        }
        
        private func notice(forFont font: String) -> Notice? {
            if font.lowercased().contains("keycaps") {
                return .keyboard
            }
            return nil
        }
    }
}
