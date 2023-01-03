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
                segmentControl
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
                name: viewModel.importName,
                ttcRepackMode: viewModel.importTTCRepackMode) {
                    viewModel.message = $0
                }
        }
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
            Picker("Custom font", selection: $viewModel.customFontPickerSelection) {
                ForEach(Array(viewModel.customFonts.enumerated()), id: \.element.name) { index, font in
                    Text(font.name)
                        .tag(index)
                }
            }
            .pickerStyle(.wheel)
        } header: {
            Text("Custom fonts")
        }
        
        Section {
            Button {
                viewModel.message = "Importing..."
                viewModel.importName = viewModel.selectedCustomFont.localPath
                viewModel.importTTCRepackMode = .woff2
                viewModel.importPresented = true
            } label: {
                Text("Import custom \(viewModel.selectedCustomFont.name)")
            }
            if let alternativeTTCRepackMode = viewModel.selectedCustomFont.alternativeTTCRepackMode  {
                Button {
                    viewModel.message = "Importing..."
                    viewModel.importName = viewModel.selectedCustomFont.localPath
                    viewModel.importTTCRepackMode = alternativeTTCRepackMode
                    viewModel.importPresented = true
                } label: {
                    Text("Import custom \(viewModel.selectedCustomFont.name) with fix for .ttc")
                }
            }
            Button {
                viewModel.message = "Running"
                viewModel.progress = Progress(totalUnitCount: 1)
                overwriteWithCustomFont(
                    name: viewModel.selectedCustomFont.localPath,
                    targetName: viewModel.selectedCustomFont.targetPath,
                    progress: viewModel.progress
                ) {
                    viewModel.message = $0
                    viewModel.progress = nil
                }
            } label: {
                Text("Apply \(viewModel.selectedCustomFont.name)")
            }
            
            if let notice = viewModel.selectedCustomFont.notice {
                NoticeView(notice: notice)
            }
        }
    }
    
    private var actionSection: some View {
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
