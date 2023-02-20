//
//  FileEditorView.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 4/1/2023.
//

import SwiftUI

struct FileEditorView: View {
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.files, id: \.self) { file in
                HStack {
                    Text(file)
                    Spacer()
                    Button {
                        viewModel.remove(file: file)
                        Task {
                            await viewModel.populateFiles()
                        }
                    } label: {
                        Image(systemName: "trash")
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.isVisibleRemoveAllAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Imported fonts", comment: "Imported fonts") + " (\(viewModel.files.count))")
        }
        .alert(isPresented: $viewModel.isVisibleRemoveAllAlert) {
            Alert(
                title: Text("Remove all"),
                message: Text("Are you sure you want to remove all imported font files?"),
                primaryButton: .destructive(Text("Remove all")) {
                    viewModel.removeAllFiles()
                    Task {
                        await viewModel.populateFiles()
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            Task {
                await viewModel.populateFiles()
            }
        }
    }
}

struct FileEditorView_Previews: PreviewProvider {
    static var previews: some View {
        FileEditorView()
    }
}
