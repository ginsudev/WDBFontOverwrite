//
//  PresetFontsScene.ViewModel.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 6/1/2023.
//

import Foundation

struct FontToReplace {
    var name: String
    var postScriptName: String
    var repackedPath: String
}

extension PresetFontsScene {
    struct ViewModel {
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
        
        nonisolated func overwrite(withName name: String) async {
            await overwriteWithFont(name: name)
            await MainActor.run {
                ProgressManager.shared.isBusy = false
            }
        }
    }
}
