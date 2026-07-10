//
//  ContentViewSnapshotTests.swift
//  EasySaving
//
//  Created by Jorge Sirvent on 5/7/26.
//

@testable import EasySaving
import SnapshotTesting
import SwiftUI
import Testing

@MainActor
struct ContentViewSnapshotTests {
    @Test
    func `placeholder view light`() {
        assertSnapshot(of: ContentView(),
                       as: .image(
                           layout: .fixed(width: 390, height: 844),
                           traits: UITraitCollection(userInterfaceStyle: .light),
                       ))
    }
}
