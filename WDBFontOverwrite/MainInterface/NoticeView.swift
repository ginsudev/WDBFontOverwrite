//
//  NoticeView.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 3/1/2023.
//

import SwiftUI

enum Notice: String {
    /// iOS not supported msg.
    case iosVersion = "iOS version not supported. Don't ask us to support newer versions because the exploit used just simply does not support newer iOS versions."
    
    /// Custom font pre-usage info.
    case beforeUse = "Custom fonts require font files that are ported for iOS. See https://github.com/ginsudev/WDBFontOverwrite for details."
    
    /// Keyboard cache issue msg.
    case keyboard = "Keyboard fonts may not be applied immediately due to iOS caching issues. IF POSSIBLE, remove the folder /var/mobile/Library/Caches/com.apple.keyboards/ if you wish for changes to take effect immediately."
}

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
