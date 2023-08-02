//
//  CustomFontsScene.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 6/1/2023.
//

import SwiftUI
import UniformTypeIdentifiers

struct CustomFontsScene: View {
    @StateObject private var viewModel = ViewModel()
    @EnvironmentObject var progressManager: ProgressManager
    @Environment(\.openURL) private var openURL
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
            VStack(spacing: 10) {
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
                                //                            restartBackboard()
                                restartFrontboard()
                                //                            restartFrontboard()
                            }.disabled(kfd == 0).frame(minWidth: 0, maxWidth: 100)
                        }}
                    Section {
                        ExplanationView(
                            systemImage: "textformat",
                            description: "Import & manage custom fonts that have been ported to iOS.",
                            canShowProgress: true
                        )
                    }
                    .listRowBackground(Color(UIColor(red: 0.44, green: 0.69, blue: 0.67, alpha: 1.00)))
                    fontsList
                    actionSection
                }
            }
            .navigationTitle("Custom")
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $viewModel.importPresented) {
            DocumentPicker(
                importType: viewModel.selectedCustomFontType,
                ttcRepackMode: viewModel.importTTCRepackMode
            )
        }
        .sheet(isPresented: $viewModel.isPresentedFileEditor) {
            FileEditorView()
        }
        .onAppear {
            Task(priority: .background) {
                do {
                    try await FontMap.populateFontMap()
                } catch {
                    progressManager.message = "Error: Unable to populate font map."
                }
            }
        }
    }
    
    @ViewBuilder
    private var fontsList: some View {
        Section {
            Picker("Custom fonts", selection: $viewModel.customFontPickerSelection) {
                Text("Custom font")
                    .tag(0)
                Text("Custom Emoji")
                    .tag(1)
            }
            .pickerStyle(.segmented)
            
            Button {
                progressManager.message = "Importing..."
                viewModel.importTTCRepackMode = .woff2
                viewModel.importPresented = true
            } label: {
                AlignedRowContentView(
                    imageName: "square.and.arrow.down",
                    text: "Import custom \(viewModel.selectedCustomFontType.rawValue)"
                )
            }
            Button {
                progressManager.isBusy = true
                progressManager.message = "Running"
                Task {
                    await viewModel.batchOverwriteFonts()
                }
            } label: {
                AlignedRowContentView(
                    imageName: "checkmark.circle",
                    text: "Apply \(viewModel.selectedCustomFontType.rawValue)"
                )
            }
        } header: {
            Text("Fonts")
        }
    }
    
    private var actionSection: some View {
        Section {
            Button {
                viewModel.isPresentedFileEditor = true
            } label: {
                AlignedRowContentView(
                    imageName: "doc.badge.gearshape",
                    text: "Manage imported fonts"
                )
            }
            ActionButtons()
        } header: {
            Text("Actions")
        } footer: {
            Text("Originally created by [@zhuowei](https://twitter.com/zhuowei). Updated & maintained by [@GinsuDev](https://twitter.com/GinsuDev).")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CustomFontsScene()
    }
}
