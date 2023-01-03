//
//  NoticeView.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 3/1/2023.
//

import SwiftUI

struct NoticeView: View {
    let notice: Notice
    
    var body: some View {
        HStack {
            Image(systemName: "info.circle")
            Text(LocalizedStringKey(notice.rawValue))
        }
    }
}

struct NoticeView_Previews: PreviewProvider {
    static var previews: some View {
        NoticeView(notice: .keyboard)
    }
}
