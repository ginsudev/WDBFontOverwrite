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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                Form {
                    Section {
                        ExplanationView(
                            systemImage: "textformat",
                            description: NSLocalizedString("Import & manage custom fonts that have been ported to iOS.", comment: "Import & manage custom fonts that have been ported to iOS."),
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
                progressManager.message = NSLocalizedString("Importing...", comment: "Importing...")
                viewModel.importTTCRepackMode = .woff2
                viewModel.importPresented = true
            } label: {
                AlignedRowContentView(
                    imageName: "square.and.arrow.down",
                    text: NSLocalizedString("Import custom \(viewModel.selectedCustomFontType.rawValue)", comment: "Import custom")
                )
            }
            Button {
                progressManager.isBusy = true
                progressManager.message = NSLocalizedString("Running", comment: "Running")
                Task {
                    await viewModel.batchOverwriteFonts()
                }
            } label: {
                AlignedRowContentView(
                    imageName: "checkmark.circle",
                    text: NSLocalizedString("Apply \(viewModel.selectedCustomFontType.rawValue)", comment: "Apply")
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
                    text: NSLocalizedString("Manage imported fonts", comment: "Manage imported fonts")
                )
            }
            ActionButtons()
        } header: {
            Text("Actions")
        } footer: {
            Text("Originally created by [@zhuowei](https://twitter.com/zhuowei). Updated & maintained by [@GinsuDev](https://twitter.com/GinsuDev). Chinese translation by [@chihaodong](https://twitter.com/chihaodong).")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CustomFontsScene()
    }
}
