//
//  ActionButtons.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 6/1/2023.
//

import SwiftUI

struct ActionButtons: View {
    private let viewModel = ViewModel()
    
    var body: some View {
        if #available(iOS 15, *) {
            Button {
                viewModel.clearKBCache()
            } label: {
                AlignedRowContentView(
                    imageName: "trash",
                    text: "Clear keyboard cache"
                )
            }
        }
        Button {
            if #available(iOS 15, *) {
                viewModel.respringModern()
            } else {
                viewModel.respringLegacy()
            }
        } label: {
            AlignedRowContentView(
                imageName: "arrow.triangle.2.circlepath",
                text: "Restart SpringBoard"
            )
        }
    }
}

struct ActionButtons_Previews: PreviewProvider {
    static var previews: some View {
        ActionButtons()
    }
}
