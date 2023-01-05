//
//  FontDiscoveryCell.ViewModel.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 5/1/2023.
//

import SwiftUI

extension FontDiscoveryCard {
    struct ViewDescriptor {
        let avatarPath: String
        let name: String
        let twitterHandle: String
        let role: CustomFontType
        let links: [FontDiscoveryLinkDescriptor]
    }
    
    struct AvatarDownloader {
        func downloadAvatar(fromURL url: String) async -> UIImage? {
            guard let url = URL(string: url) else {
                return nil
            }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                let image = handleResponse(data: data, response: response)
                return image
            } catch {
                print("Unable to load avatar for card")
                return nil
            }
        }
        
        private func handleResponse(data: Data?, response: URLResponse?) -> UIImage? {
            guard let data,
                  let image = UIImage(data: data),
                  let response = response as? HTTPURLResponse,
                  (200..<300).contains(response.statusCode) else {
                    print("No image")
                    return nil
            }
            return image
        }
    }
    
    final class ViewModel: ObservableObject {
        let downloader = AvatarDownloader()
        @Published var image = Image(systemName: "person.crop.circle")

        func fetchImage(fromURL url: String) async {
            if let image = await self.downloader.downloadAvatar(fromURL: url) {
                await MainActor.run { [weak self] in
                    self?.image = Image(uiImage: image)
                }
            }
        }
    }
}
