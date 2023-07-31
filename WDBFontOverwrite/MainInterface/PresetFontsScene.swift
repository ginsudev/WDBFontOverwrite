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
    @State private var kfd: UInt64 = 0
    
    private var puaf_pages_options = [16, 32, 64, 128, 256, 512, 1024, 2048]
    @State private var puaf_pages_index = 7
    @State private var puaf_pages = 0
    
    private var puaf_method_options = ["physpuppet", "smith"]
    @State private var puaf_method = 1
    
    private var kread_method_options = ["kqueue_workloop_ctl", "sem_open"]
    @State private var kread_method = 1
    
    private var kwrite_method_options = ["dup", "sem_open"]
    @State private var kwrite_method = 1
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker(selection: $puaf_pages_index, label: Text("puaf pages:")) {
                        ForEach(0 ..< puaf_pages_options.count, id: \.self) {
                            Text(String(self.puaf_pages_options[$0]))
                        }
                    }.disabled(kfd != 0)
                }
                Section {
                    Picker(selection: $puaf_method, label: Text("puaf method:")) {
                        ForEach(0 ..< puaf_method_options.count, id: \.self) {
                            Text(self.puaf_method_options[$0])
                        }
                    }.disabled(kfd != 0)
                }
                Section {
                    Picker(selection: $kread_method, label: Text("kread method:")) {
                        ForEach(0 ..< kread_method_options.count, id: \.self) {
                            Text(self.kread_method_options[$0])
                        }
                    }.disabled(kfd != 0)
                }
                Section {
                    Picker(selection: $kwrite_method, label: Text("kwrite method:")) {
                        ForEach(0 ..< kwrite_method_options.count, id: \.self) {
                            Text(self.kwrite_method_options[$0])
                        }
                    }.disabled(kfd != 0)
                }
                Section {
                    HStack {
                        Button("kopen") {
                            puaf_pages = puaf_pages_options[puaf_pages_index]
                            kfd = do_kopen(UInt64(puaf_pages), UInt64(puaf_method), UInt64(kread_method), UInt64(kwrite_method))
                            do_fun()
                        }.disabled(kfd != 0).frame(minWidth: 0, maxWidth: .infinity)
                        Button("kclose") {
                            do_kclose(kfd)
                            puaf_pages = 0
                            kfd = 0
                        }.disabled(kfd == 0).frame(minWidth: 0, maxWidth: .infinity)
                        Button("respring") {
                            restartBackboard()
//                            restartFrontboard()
                        }.disabled(kfd == 0).frame(minWidth: 0, maxWidth: 100)
                    }
                    Section {
                        ExplanationView(
                            systemImage: "textformat",
                            description: "Choose from a selection of preset fonts.",
                            canShowProgress: true
                        )
                    }
                    .listRowBackground(Color(UIColor(red: 0.44, green: 0.69, blue: 0.67, alpha: 1.00)))
                    fontsSection
                    actionSection
                }
                .navigationTitle("Presets")
            }
            .navigationViewStyle(.stack)
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
            Text("Originally created by [@zhuowei](https://twitter.com/zhuowei). KFD fork by [@htrowii](https://twitter.com/htrowii). Updated & maintained by [@GinsuDev](https://twitter.com/GinsuDev).")
        }
    }
}

struct PresetsScene_Previews: PreviewProvider {
    static var previews: some View {
        PresetFontsScene()
    }
}
