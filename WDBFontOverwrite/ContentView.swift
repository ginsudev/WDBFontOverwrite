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
            VStack(spacing: 20) {
                progressView
                List {
                    fontsList
                    customFontsList
                }
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
    
    @ViewBuilder
    private var customFontsList: some View {
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
                Button {
                    viewModel.message = "Importing..."
                    viewModel.importName = font.localPath
                    viewModel.importTTCRepackMode = font.alternativeTTCRepackMode
                    viewModel.importPresented = true
                } label: {
                    Text("Import custom \(font.name) with fix for .ttc")
                }
            } header: {
                Text(font.name)
            }
        }
        Text(
            "Custom fonts require font files that are ported for iOS.\nSee https://github.com/zhuowei/WDBFontOverwrite for details."
        )
        .font(.system(size: 12))
    }
}

class WDBImportCustomFontPickerViewControllerDelegate: NSObject, UIDocumentPickerDelegate {
    let name: String
    let ttcRepackMode: TTCRepackMode
    let completion: (String) -> Void
    init(name: String, ttcRepackMode: TTCRepackMode, completion: @escaping (String) -> Void) {
        self.name = name
        self.ttcRepackMode = ttcRepackMode
        self.completion = completion
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL])
    {
        guard urls.count == 1 else {
            completion("import one file at a time")
            return
        }
        DispatchQueue.global(qos: .userInteractive).async {
            let fileURL = urls[0]
            let documentDirectory = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask)[0]
            let targetURL = documentDirectory.appendingPathComponent(self.name)
            let success = importCustomFontImpl(
                fileURL: fileURL, targetURL: targetURL, ttcRepackMode: self.ttcRepackMode)
            DispatchQueue.main.async {
                self.completion(success ?? "Imported")
            }
        }
    }
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completion("Cancelled")
    }
}

// https://capps.tech/blog/read-files-with-documentpicker-in-swiftui
struct DocumentPicker: UIViewControllerRepresentable {
    let controllerDelegate: WDBImportCustomFontPickerViewControllerDelegate
    init(name: String, ttcRepackMode: TTCRepackMode, completion: @escaping (String) -> Void) {
        controllerDelegate = WDBImportCustomFontPickerViewControllerDelegate(
            name: name, ttcRepackMode: ttcRepackMode, completion: completion)
    }
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        print("make ui view controller?")
        let pickerViewController = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                UTType.font, UTType(filenameExtension: "woff2", conformingTo: .font)!,
            ], asCopy: true)
        pickerViewController.delegate = self.controllerDelegate
        return pickerViewController
    }
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context)
    {}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
