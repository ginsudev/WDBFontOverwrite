//
//  ContentView.swift
//  WDBFontOverwrite
//
//  Created by Zhuowei Zhang on 2022-12-25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationView {
            Form {
                progressView
                listPickerView
                if viewModel.fontListSelection == 0 {
                    fontsList
                } else {
                    customFontsList
                }
                actionSection
            }
            .navigationTitle("WDBFontOverwrite")
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $viewModel.importPresented) {
            DocumentPicker(
                importType: viewModel.importType,
                ttcRepackMode: viewModel.importTTCRepackMode
            ) {
                viewModel.message = $0
            }
        }
        .sheet(isPresented: $viewModel.isPresentedFileEditor) {
            FileEditorView()
        }
        .onAppear {
            Task(priority: .background) {
                do {
                    try await FontMap.populateFontMap()
                } catch {
                    viewModel.message = "Error: Unable to populate font map."
                }
            }
        }
    }
    
    private var listPickerView: some View {
        Picker("Font choice", selection: $viewModel.fontListSelection) {
            Text("Preset")
                .tag(0)
            Text("Custom")
                .tag(1)
        }
        .pickerStyle(.segmented)
    }
    
    @ViewBuilder
    private var progressView: some View {
        if #available(iOS 16.2, *) {
            NoticeView(notice: .iosVersion)
                .bold()
                .foregroundColor(.red)
        } else {
            Text(viewModel.message)
        }
        if let progress = viewModel.progress {
            ProgressView(progress)
        }
    }
    
    private var fontsList: some View {
        Section {
            ForEach(viewModel.fonts, id: \.name) { font in
                Button {
                    viewModel.message = "Running"
                    viewModel.progress = Progress(totalUnitCount: 1)
                    overwriteWithFont(
                        name: font.repackedPath,
                        progress: viewModel.progress
                    ) {
                        viewModel.message = $0
                        viewModel.progress = nil
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
    
    @ViewBuilder
    private var customFontsList: some View {
        Section {
            NoticeView(notice: .beforeUse)
            Picker("Custom fonts", selection: $viewModel.customFontPickerSelection) {
                Text("Custom font")
                    .tag(0)
                Text("Custom Emoji")
                    .tag(1)
            }
            .pickerStyle(.wheel)
            
            Button {
                viewModel.message = "Importing..."
                viewModel.importTTCRepackMode = .woff2
                viewModel.importPresented = true
            } label: {
                Text("Import custom \(viewModel.selectedCustomFontType.rawValue)")
            }
            if viewModel.selectedCustomFontType == .font {
                Button {
                    viewModel.message = "Importing..."
                    viewModel.importTTCRepackMode = .ttcpad
                    viewModel.importPresented = true
                } label: {
                    Text("Import custom \(viewModel.selectedCustomFontType.rawValue) with fix for .ttc")
                }
            }
            Button {
                viewModel.message = "Running"
                viewModel.progress = Progress(totalUnitCount: 1)
                Task {
                    await viewModel.batchOverwriteFonts()
                }
            } label: {
                Text("Apply \(viewModel.selectedCustomFontType.rawValue)")
            }
        } header: {
            Text("Custom fonts")
        }
    }
    
    private var actionSection: some View {
        Section {
            Button {
                viewModel.isPresentedFileEditor = true
            } label: {
                Text("Manage imported fonts")
            }
            Button {
                let sharedApplication = UIApplication.shared
                let windows = sharedApplication.windows
                if let window = windows.first {
                    while true {
                        window.snapshotView(afterScreenUpdates: false)
                    }
                }
            } label: {
                Text("Restart SpringBoard")
            }
        } header: {
            Text("Actions")
        } footer: {
            Text("Originally created by [@zhuowei](https://twitter.com/zhuowei). Updated & maintained by [@GinsuDev](https://twitter.com/GinsuDev).")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
