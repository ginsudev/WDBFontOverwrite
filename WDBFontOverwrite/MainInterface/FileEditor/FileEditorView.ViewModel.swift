//
//  FileEditorView.ViewModel.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 4/1/2023.
//

import Foundation

extension FileEditorView {
    final class ViewModel: ObservableObject {
        let fileManager = FileManager.default
        @Published var files = [String]()
        @Published var isVisibleRemoveAllAlert = false
        
        func populateFiles() async {
            do {
                let path = documentsDirectory().relativePath
                
                try await MainActor.run { [weak self] in
                    self?.files = try fileManager.contentsOfDirectory(atPath: path)
                }
            } catch {
                print(error)
            }
        }
        
        func remove(file: String) {
            do {
                try fileManager.removeItem(at: documentsDirectory().appendingPathComponent(file))
            } catch {
                print(error)
            }
        }
        
        func removeAllFiles() {
            for file in files {
                remove(file: file)
            }
        }
        
        private func documentsDirectory() -> URL {
            return fileManager.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]
        }
    }
}
