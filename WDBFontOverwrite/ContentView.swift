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
        overwriteWithFiraSans {
          message = $0
        }
      }) {
        Text("Fira Sans").font(.custom("FiraSans-Regular", size: 18))
      }.padding(16)
      Button(action: {
        message = "Running"
        overwriteWithRobotoSerif {
          message = $0
        }
      }) {
        Text("Roboto Serif").font(.custom("RobotoSerif-20ptRegular", size: 18))
      }.padding(16)
      Button(action: {
        message = "Running"
        overwriteWithNotoSansMono {
          message = $0
        }
      }) {
        Text("Noto Sans Mono").font(.custom("NotoSansMono-Regular", size: 18))
      }.padding(16)
      Button(action: {
        message = "Running"
        overwriteWithChocoCooky {
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
