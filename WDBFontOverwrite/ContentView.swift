//
//  ContentView.swift
//  WDBFontOverwrite
//
//  Created by Zhuowei Zhang on 2022-12-25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
          Button(action: overwriteWithFiraSans) {
            Text("Fira Sans").font(.custom("FiraSans-Regular", size: 18))
          }.padding(16)
          Button(action: overwriteWithRobotoSerif) {
            Text("Roboto Serif").font(.custom("RobotoSerif-20ptRegular", size: 18))
          }.padding(16)
          Button(action: overwriteWithNotoSansMono) {
            Text("Noto Sans Mono").font(.custom("NotoSansMono-Regular", size: 18))
          }.padding(16)
          Button(action: overwriteWithChocoCooky) {
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
