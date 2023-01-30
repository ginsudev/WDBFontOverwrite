//
//  ActionButtons.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 6/1/2023.
//

import SwiftUI

struct ActionButtons: View {
    var body: some View {
        if #available(iOS 15, *) {
            Button {
                clearKBCache()
            } label: {
                AlignedRowContentView(
                    imageName: "trash",
                    text: "Clear keyboard cache"
                )
            }
        }
        Button {
            respring()
        } label: {
            AlignedRowContentView(
                imageName: "arrow.triangle.2.circlepath",
                text: "Restart SpringBoard"
            )
        }
    }
    
    private func clearKBCache() {
        grant_full_disk_access { error in
            if error != nil {
                print("can't get disk access")
            } else {
                _UIKeyboardCache.purge()
            }
        }
    }
    
    private func respring() {
        grant_full_disk_access { error in
            if error != nil {
                print("can't get disk access")
            } else {
                xpc_crasher(UnsafeMutablePointer<Int8>(mutating: "com.apple.frontboard.systemappservices"))
            }
        }
    }
}

struct ActionButtons_Previews: PreviewProvider {
    static var previews: some View {
        ActionButtons()
    }
}
