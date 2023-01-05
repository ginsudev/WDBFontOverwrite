//
//  FontDiscoveryCell.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 5/1/2023.
//

import SwiftUI

// MARK: - Public

struct FontDiscoveryCard: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel = ViewModel()
    let descriptor: ViewDescriptor
    
    var body: some View {
        VStack(alignment: .leading) {
            header
            links
        }
        .frame(maxWidth: .infinity)
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.secondary, lineWidth: 1)
        )
        .onAppear {
            Task {
                await viewModel.fetchImage(fromURL: descriptor.avatarPath)
            }
        }
    }
}

// MARK: - Private

private extension FontDiscoveryCard {
    var header: some View {
        HStack {
            viewModel.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.secondary, lineWidth: 1)
                        .foregroundColor(.clear)
                )
            VStack(alignment: .leading) {
                Text(descriptor.name)
                    .font(.title2)
                Text(descriptor.role.rawValue.uppercased())
                    .foregroundColor(.secondary)
                    .font(.footnote)
                    .bold()
            }
            Spacer()
        }
    }
    
    var links: some View {
        HStack {
            ForEach(descriptor.links, id: \.title) { link in
                Button {
                    openURL(link.url)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: link.imageName)
                        Text(link.title)
                    }
                    .foregroundColor(.white)
                }
                .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                .background(Color(UIColor(red: 0.44, green: 0.69, blue: 0.67, alpha: 1.00)))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
