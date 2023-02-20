//
//  ToolsManager.swift
//  WDBFontOverwrite
//
//  Created by 迟浩东 on 2023/2/20.
//

import UIKit

/* 注销重启 */
func respring() {
    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    
    let view = UIView(frame: UIScreen.main.bounds)
    view.backgroundColor = .black
    view.alpha = 0

    for window in UIApplication.shared.connectedScenes.map({ $0 as? UIWindowScene }).compactMap({ $0 }).flatMap({ $0.windows.map { $0 } }) {
        window.addSubview(view)
        UIView.animate(withDuration: 0.2, delay: 0, animations: {
            view.alpha = 1
        })
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
        restartFrontboard()
        exit(0)
    })
}
