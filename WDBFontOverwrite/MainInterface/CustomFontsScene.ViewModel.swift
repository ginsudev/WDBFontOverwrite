//
//  CustomFontsScene.ViewModel.swift
//  WDBFontOverwrite
//
//  Created by Noah Little (@ginsudev) on 31/12/2022.
//

import Foundation

struct CustomFont {
    var name: String
    var targetPaths: [String]
    var localPath: String
    var notice: Notice?
}

enum CustomFontType: String {
    case font = "fonts"
    case emoji = "emojis"
}

extension CustomFontsScene {
    final class ViewModel: ObservableObject {
        @Published var customFontPickerSelection: Int = 0
        @Published var importPresented: Bool = false
        @Published var isPresentedFileEditor: Bool = false
        @Published var importTTCRepackMode: TTCRepackMode = .woff2
        @Published var importType: CustomFontType = .font
        
        var selectedCustomFontType: CustomFontType {
            customFontPickerSelection == 0 ? .font : .emoji
        }
        
        func batchOverwriteFonts() async {
            guard selectedCustomFontType == .font else {
                // Overwrite emoji
                let emojiFont = FontMap.emojiCustomFont
                await overwriteWithCustomFont(
                    name: emojiFont.localPath,
                    targetPaths: emojiFont.targetPaths
                )
                await MainActor.run {
                    ProgressManager.shared.isBusy = false
                }
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
                            targetPaths: customFont.targetPaths
                        )
                    }
                }
                await MainActor.run {
                    ProgressManager.shared.isBusy = false
                }
            } catch  {
                print(error)
                await MainActor.run {
                    ProgressManager.shared.message = "Failed to read imported fonts."
                }
            }
        }
    }
}
