//
//  FontDiscoveryView.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 5/1/2023.
//

import SwiftUI

struct FontDiscoveryScene: View {
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                VStack(spacing: 10) {
                    ExplanationView(
                        systemImage: "star.fill",
                        description: "Find fonts and emojis from these talented developers and themers.",
                        canShowProgress: false
                    )
                    ForEach(viewModel.descriptors, id: \.name) { descriptor in
                        Section {
                            FontDiscoveryCard(descriptor: descriptor)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                        }
                    }
                    Spacer()
                }
            }
            .navigationTitle("Discovery")
        }
        .navigationViewStyle(.stack)
    }
}

struct FontDiscoveryView_Previews: PreviewProvider {
    static var previews: some View {
        FontDiscoveryScene()
    }
}
