//
//  RespringButton.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 6/1/2023.
//

import SwiftUI

struct RespringButton: View {
    var body: some View {
        Button {
            respring()
        } label: {
            AlignedRowContentView(
                imageName: "arrow.triangle.2.circlepath",
                text: "Restart SpringBoard"
            )
        }
    }
    
    private func respring() {
        let sharedApplication = UIApplication.shared
        let windows = sharedApplication.windows
        if let window = windows.first {
            while true {
                window.snapshotView(afterScreenUpdates: false)
            }
        }
    }
}

struct RespringButton_Previews: PreviewProvider {
    static var previews: some View {
        RespringButton()
    }
}
