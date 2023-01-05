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
    @StateObject private var progressManager = ProgressManager.shared
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
                importType: viewModel.selectedCustomFontType,
                ttcRepackMode: viewModel.importTTCRepackMode
            ) {
                viewModel.message = $0
            }
        }
        .sheet(isPresented: $viewModel.isPresentedFileEditor) {
            FileEditorView()
        }
        .sheet(isPresented: $viewModel.isPresentedFontDiscovery) {
            FontDiscoveryView()
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
        if progressManager.isBusy {
            ProgressView(
                value: progressManager.completedProgress,
                total: progressManager.totalProgress
            )
            .progressViewStyle(.linear)
        }
    }
    
    private var fontsList: some View {
        Section {
            ForEach(viewModel.fonts, id: \.name) { font in
                Button {
                    viewModel.message = "Running"
                    Task {
                        await overwriteWithFont(name: font.repackedPath) {
                            viewModel.message = $0
                        }
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
            Button {
                viewModel.isPresentedFontDiscovery = true
            } label: {
                AlignedRowContentView(
                    imageName: "star",
                    text: "Find custom fonts/emoji here"
                )
            }

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
                AlignedRowContentView(
                    imageName: "square.and.arrow.down",
                    text: "Import custom \(viewModel.selectedCustomFontType.rawValue)"
                )
            }
            if viewModel.selectedCustomFontType == .font {
                Button {
                    viewModel.message = "Importing..."
                    viewModel.importTTCRepackMode = .ttcpad
                    viewModel.importPresented = true
                } label: {
                    AlignedRowContentView(
                        imageName: "square.and.arrow.down",
                        text: "Import custom \(viewModel.selectedCustomFontType.rawValue) with fix for .ttc"
                    )
                }
            }
            Button {
                progressManager.isBusy = true
                viewModel.message = "Running"
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
            Text("Custom fonts")
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
            Button {
                let sharedApplication = UIApplication.shared
                let windows = sharedApplication.windows
                if let window = windows.first {
                    while true {
                        window.snapshotView(afterScreenUpdates: false)
                    }
                }
            } label: {
                AlignedRowContentView(
                    imageName: "arrow.triangle.2.circlepath",
                    text: "Restart SpringBoard"
                )
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
