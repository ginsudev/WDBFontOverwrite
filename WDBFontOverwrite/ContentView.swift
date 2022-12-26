//
//  ContentView.swift
//  WDBFontOverwrite
//
//  Created by Zhuowei Zhang on 2022-12-25.
//

import SwiftUI

struct ContentView: View {
  @State private var message = "Choose a font."
  var body: some View {
    VStack {
      Text(message).padding(16)
      Button(action: {
        message = "Running"
        overwriteWithFont(name: "DejaVuSansCondensed.woff2") {
          message = $0
        }
      }) {
        Text("DejaVu Sans Condensed").font(.custom("DejaVuSansCondensed", size: 18))
      }.padding(16)
      Button(action: {
        message = "Running"
        overwriteWithFont(name: "DejaVuSerif.woff2") {
          message = $0
        }
      }) {
        Text("DejaVu Serif").font(.custom("DejaVuSerif", size: 18))
      }.padding(16)
      Button(action: {
        message = "Running"
        overwriteWithFont(name: "DejaVuSansMono.woff2") {
          message = $0
        }
      }) {
        Text("DejaVu Sans Mono").font(.custom("DejaVuSansMono", size: 18))
      }.padding(16)
      Button(action: {
        message = "Running"
        overwriteWithFont(name: "Chococooky.woff2") {
          message = $0
        }
      }) {
        Text("Choco Cooky").font(.custom("Chococooky", size: 18))
      }.padding(16)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
