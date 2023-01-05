//
//  FontDiscoveryView.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 5/1/2023.
//

import SwiftUI

struct FontDiscoveryView: View {
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                message
                ForEach(viewModel.descriptors, id: \.name) { descriptor in
                    Section {
                        FontDiscoveryCard(descriptor: descriptor)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                    }
                }
                .navigationTitle("Discovery")
                Spacer()
            }
        }
    }
    
    private var message: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(UIColor(red: 0.44, green: 0.69, blue: 0.67, alpha: 1.00)))
            VStack(alignment: .center) {
                Image(systemName: "star.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundColor(.white)
                Text("Find fonts and emojis from these talented developers and themers.")
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal)
    }
}

struct FontDiscoveryView_Previews: PreviewProvider {
    static var previews: some View {
        FontDiscoveryView()
    }
}
