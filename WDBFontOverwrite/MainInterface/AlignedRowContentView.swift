//
//  AlignedRowContentView.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 5/1/2023.
//

import SwiftUI

struct AlignedRowContentView: View {
    let imageName: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: imageName)
                .font(.system(size: 20))
                .frame(width: 32, height: 32)
                .alignmentGuide(.leading) { d in d[HorizontalAlignment.center] }
            Text(text)
                .alignmentGuide(.leading) { d in d[HorizontalAlignment.leading] }
        }
    }
}

struct AlignedRowContentView_Previews: PreviewProvider {
    static var previews: some View {
        AlignedRowContentView(
            imageName: "trash",
            text: "Lol"
        )
    }
}
