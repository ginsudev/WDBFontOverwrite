//
//  ProgressManager.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 5/1/2023.
//

import Foundation

@MainActor
final class ProgressManager: ObservableObject {
    enum ImportStatus {
        case success
        case failure(String)
    }
    
    static let shared = ProgressManager()
    @Published var completedProgress: Double = 0
    @Published var totalProgress: Double = 0
    @Published var importResults = [ImportStatus]()
    @Published var message: String = NSLocalizedString("Choose a font.", comment: "Choose a font.")
    
    @Published var isPresentedResultsAlert = false {
        didSet {
            if !isPresentedResultsAlert {
                importResults = []
                message = NSLocalizedString("Done.", comment: "Done.")
            }
        }
    }
    
    var isBusy: Bool = false {
        didSet {
            if !isBusy {
                // Reset values when done.
                completedProgress = 0
                totalProgress = 0
                isPresentedResultsAlert = true
            }
        }
    }
}
