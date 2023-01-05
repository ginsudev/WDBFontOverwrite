//
//  FontDiscoveryView.ViewModel.swift
//  WDBFontOverwrite
//
//  Created by Noah Little on 5/1/2023.
//

import Foundation

struct FontDiscoveryLinkDescriptor {
    let url: URL
    let title: String
    let imageName: String
}

extension FontDiscoveryView {
    final class ViewModel: ObservableObject {
        let descriptors = [
            FontDiscoveryCard.ViewDescriptor(
                avatarPath: "https://unavatar.io/github/evynw",
                name: "Evelyn",
                twitterHandle: "ev_ynw",
                role: .font,
                links: [
                    .init(
                        url: URL(string: "https://twitter.com/ev_ynw")!,
                        title: "Twitter",
                        imageName: "person.crop.circle.badge.plus"
                    ),
                    .init(
                        url: URL(string: "https://bit.ly/3e3nJdm")!,
                        title: "Font library",
                        imageName: "books.vertical"
                    )
                ]
            ),
            FontDiscoveryCard.ViewDescriptor(
                avatarPath: "https://unavatar.io/github/PoomSmart",
                name: "PoomSmart",
                twitterHandle: "PoomSmart",
                role: .emoji,
                links: [
                    .init(
                        url: URL(string: "https://twitter.com/PoomSmart")!,
                        title: "Twitter",
                        imageName: "person.crop.circle.badge.plus"
                    ),
                    .init(
                        url: URL(string: "https://github.com/PoomSmart/EmojiFonts/releases")!,
                        title: "Emoji library",
                        imageName: "face.smiling"
                    )
                ]
            ),
            FontDiscoveryCard.ViewDescriptor(
                avatarPath: "https://unavatar.io/github/AlexMan1979",
                name: "AlexMan1979",
                twitterHandle: "AlexMan1979",
                role: .font,
                links: [
                    .init(
                        url: URL(string: "https://twitter.com/AlexMan1979")!,
                        title: "Twitter",
                        imageName: "person.crop.circle.badge.plus"
                    )
                ]
            ),
        ]
    }
}
