//
//  WDBFontOverwriteApp.swift
//  WDBFontOverwrite
//
//  Created by Zhuowei Zhang on 2022-12-25.
//

import SwiftUI

@main
struct WDBFontOverwriteApp: App {
    @StateObject private var progressManager = ProgressManager.shared

    var body: some Scene {
        WindowGroup {
            TabView {
                PresetFontsScene()
                    .tabItem {
                        Label("Presets", systemImage: "list.dash")
                    }
                CustomFontsScene()
                    .tabItem {
                        Label("Custom", systemImage: "plus")
                    }
                FontDiscoveryScene()
                    .tabItem {
                        Label("Discovery", systemImage: "star")
                    }
            }
            .environmentObject(progressManager)
        }
    }
}
