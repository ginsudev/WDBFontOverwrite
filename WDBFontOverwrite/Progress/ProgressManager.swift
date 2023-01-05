//
//  ProgressManager.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 5/1/2023.
//

import Foundation

final class ProgressManager: ObservableObject {
    static let shared = ProgressManager()
    var isBusy: Bool = false
    @Published var completedProgress: Double = 0
    @Published var totalProgress: Double = 0
}
