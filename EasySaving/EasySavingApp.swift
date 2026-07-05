//
//  EasySavingApp.swift
//  EasySaving
//
//  Created by Jorge Sirvent on 3/7/26.
//

import SwiftUI
import EasySavingData

@main
struct EasySavingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(linkProof: DataPlaceholder().text)
        }
    }
}
