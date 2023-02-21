//
//  PresetFontsScene.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 6/1/2023.
//

import SwiftUI

struct PresetFontsScene: View {
    @EnvironmentObject private var progressManager: ProgressManager
    private let viewModel = ViewModel()
    @State private var versionBuildString: String?

    var body: some View {
        NavigationView {
            Form {
                Section {
                    ExplanationView(
                        systemImage: "textformat",
                        description: NSLocalizedString("Choose from a selection of preset fonts.", comment: "Choose from a selection of preset fonts."),
                        canShowProgress: true
                    )
                }
                .listRowBackground(Color(UIColor(red: 0.44, green: 0.69, blue: 0.67, alpha: 1.00)))
                fontsSection
                actionSection
                Section { 
                } header: {
                    Label("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "UNKNOWN") (\(versionBuildString ?? "Release"))", systemImage: "info")
                }
            }
            .navigationTitle("Presets")
        }
        .navigationViewStyle(.stack)
        .onAppear {
            if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String, build != "0" {
                versionBuildString = "Beta \(build)"
            }
        }
    }
}

private extension PresetFontsScene {
    var fontsSection: some View {
        Section {
            ForEach(viewModel.fonts, id: \.name) { font in
                Button {
                    progressManager.isBusy = true
                    progressManager.message = "Running"
                    Task {
                        await viewModel.overwrite(withName: font.repackedPath)
                    }
                } label: {
                    Text(font.name)
                        .font(.custom(
                            font.postScriptName,
                            size: 18)
                        )
                }
            }
        } header: {
            Text("Fonts")
        }
    }
    
    private var actionSection: some View {
        Section {
            ActionButtons()
        } header: {
            Text("Actions")
        } footer: {
            Text("Originally created by [@zhuowei](https://twitter.com/zhuowei). Updated & maintained by [@GinsuDev](https://twitter.com/GinsuDev). Chinese translation by [@chihaodong](https://twitter.com/chihaodong).")
        }
    }
}

struct PresetsScene_Previews: PreviewProvider {
    static var previews: some View {
        PresetFontsScene()
    }
}
