//
//  ProgressManager.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 5/1/2023.
//

import Foundation

final class ProgressManager: ObservableObject {
    static let shared = ProgressManager()
    @Published var completedProgress: Double = 0
    @Published var totalProgress: Double = 0
    
    var isBusy: Bool = false {
        didSet {
            if !isBusy {
                // Reset values when done.
                Task { @MainActor in
                    completedProgress = 0
                    totalProgress = 0
                }
            }
        }
    }
}
