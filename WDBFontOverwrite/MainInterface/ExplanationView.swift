//
//  ExplanationView.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 6/1/2023.
//

import SwiftUI

// MARK: - Public

struct ExplanationView: View {
    @EnvironmentObject var progressManager: ProgressManager
    let systemImage: String
    let description: String
    let canShowProgress: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(UIColor(
                    red: 0.44,
                    green: 0.69,
                    blue: 0.67,
                    alpha: 1.00
                )))
            VStack(alignment: .center, spacing: 10) {
                imageView
                descriptionView
                progressView
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal)
    }
}

// MARK: - Private

private extension ExplanationView {
    var imageView: some View {
        Image(systemName: systemImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 35, height: 35)
            .foregroundColor(.white)
    }
    
    var descriptionView: some View {
        Text(description)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    var progressView: some View {
        if canShowProgress {
            VStack(alignment: .center) {
                Divider()
                Text(progressManager.message)
                    .foregroundColor(.white)
                if progressManager.isBusy {
                    ProgressView(
                        value: progressManager.completedProgress,
                        total: progressManager.totalProgress
                    )
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                }
            }
        }
    }
}
