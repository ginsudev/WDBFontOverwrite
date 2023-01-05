//
//  ContentView.ViewModel.swift
//  WDBFontOverwrite
//
//  Created by Noah Little (@ginsudev) on 3/1/2023.
//

import SwiftUI
import UniformTypeIdentifiers

class WDBImportCustomFontPickerViewControllerDelegate: NSObject, UIDocumentPickerDelegate {
    let importType: CustomFontType
    let ttcRepackMode: TTCRepackMode
    let completion: (String) -> Void
    
    init(importType: CustomFontType, ttcRepackMode: TTCRepackMode, completion: @escaping (String) -> Void) {
        self.importType = importType
        self.ttcRepackMode = ttcRepackMode
        self.completion = completion
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        Task {
            await importSelectedFonts(atURLs: urls)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completion("Cancelled")
    }
    
    private func importSelectedFonts(atURLs urls: [URL]) async {
        let documentDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        
        var successfullyImportedCount = 0
        
        // Import selected font files into the documents directory, one by one.
        for url in urls {
            if importType == .emoji {
                let emojiFont = FontMap.emojiCustomFont
                let targetURL = documentDirectory.appendingPathComponent(emojiFont.localPath)
                let success = await importFont(withFileURL: url, targetURL: targetURL)
                successfullyImportedCount += success
            } else {
                let key = FontMap.key(forFont: url.lastPathComponent)
                if let customFont = FontMap.fontMap[key] {
                    let targetURL = documentDirectory.appendingPathComponent(customFont.localPath)
                    let success = await importFont(withFileURL: url, targetURL: targetURL)
                    successfullyImportedCount += success
                }
            }
        }

        await MainActor.run { [weak self] in
            self?.completion(
                String(
                    format: "Successfully imported %d/%d files.%@",
                    successfullyImportedCount,
                    urls.count,
                    successfullyImportedCount == urls.count ? "" : " Some files were skipped because your device doesn't have those fonts or because they don't support your iOS/device."
                )
            )
        }
    }
    
    private func importFont(withFileURL fileURL: URL, targetURL: URL) async -> Int {
        let success = await importCustomFontImpl(
            fileURL: fileURL,
            targetURL: targetURL,
            ttcRepackMode: self.ttcRepackMode
        )
        if success == nil {
            return 1
        } else {
            return 0
        }
    }
}

// https://capps.tech/blog/read-files-with-documentpicker-in-swiftui
struct DocumentPicker: UIViewControllerRepresentable {
    var importType: CustomFontType
    var ttcRepackMode: TTCRepackMode
    var completion: (String) -> Void
    
    func makeCoordinator() -> WDBImportCustomFontPickerViewControllerDelegate {
        return WDBImportCustomFontPickerViewControllerDelegate(
            importType: importType,
            ttcRepackMode: ttcRepackMode,
            completion: completion
        )
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
        let pickerViewController = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                UTType(
                    filenameExtension: "ttf",
                    conformingTo: .font
                )!,
                UTType(
                    filenameExtension: "ttc",
                    conformingTo: .font
                )!,
                UTType(
                    filenameExtension: "woff2",
                    conformingTo: .font
                )!,
            ],
            asCopy: true
        )
        
        pickerViewController.allowsMultipleSelection = importType == .font
        pickerViewController.delegate = context.coordinator
        return pickerViewController
    }
    
    func updateUIViewController(
        _ uiViewController: UIDocumentPickerViewController,
        context: UIViewControllerRepresentableContext<DocumentPicker>
    ) {}
}
