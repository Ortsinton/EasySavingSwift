//
//  ContentView.swift
//  EasySaving
//
//  Created by Jorge Sirvent on 3/7/26.
//

import EasySavingCore
import SwiftUI

struct ContentView: View {
    let linkProof: String
    var body: some View {
        VStack {
            Text(CorePlaceholder().text)
            Text(linkProof)
        }
    }
}

#Preview {
    ContentView(linkProof: "PlaceholderText")
}
