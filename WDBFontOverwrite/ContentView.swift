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
    
    var body: some View {
        NavigationView {
            Form {
                progressView
                segmentControl
                if viewModel.fontListSelection == 0 {
                    fontsList
                } else {
                    customFontsList
                }
                respringSection
            }
            .navigationTitle(viewModel.message)
            .sheet(isPresented: $viewModel.importPresented) {
                DocumentPicker(
                    name: viewModel.importName,
                    ttcRepackMode: viewModel.importTTCRepackMode) {
                        viewModel.message = $0
                    }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private var segmentControl: some View {
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
                    overwriteWithFont(name: font.repackedPath, progress: viewModel.progress) {
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
    
    private var respringSection: some View {
        Section {
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
            Text("Respring")
        }
    }
    
    private var customFontNoticeSection: some View {
        Section {
            HStack {
                Image(systemName: "info.circle")
                Text(
                    "Custom fonts require font files that are ported for iOS.\n\nSee https://github.com/ginsudev/WDBFontOverwrite for details."
                )
                .font(.system(size: 12))
            }
        } header: {
            Text("Notice")
        }
    }
    
    @ViewBuilder
    private var customFontsList: some View {
        customFontNoticeSection
        ForEach(viewModel.customFonts, id: \.name) { font in
            Section {
                Button {
                    viewModel.message = "Running"
                    viewModel.progress = Progress(totalUnitCount: 1)
                    overwriteWithCustomFont(
                        name: font.localPath,
                        targetName: font.targetPath,
                        targetNames: font.targetPaths,
                        progress: viewModel.progress
                    ) {
                        viewModel.message = $0
                        viewModel.progress = nil
                    }
                } label: {
                    Text("Custom \(font.name)")
                }
                Button {
                    viewModel.message = "Importing..."
                    viewModel.importName = font.localPath
                    viewModel.importTTCRepackMode = .woff2
                    viewModel.importPresented = true
                } label: {
                    Text("Import custom \(font.name)")
                }
                if let alternativeTTCRepackMode = font.alternativeTTCRepackMode  {
                    Button {
                        viewModel.message = "Importing..."
                        viewModel.importName = font.localPath
                        viewModel.importTTCRepackMode = alternativeTTCRepackMode
                        viewModel.importPresented = true
                    } label: {
                        Text("Import custom \(font.name) with fix for .ttc")
                    }
                }
            } header: {
                Text(font.name)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
