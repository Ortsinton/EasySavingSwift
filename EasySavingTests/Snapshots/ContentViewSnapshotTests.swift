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
        assertSnapshot(of: ContentView(linkProof: "snapshot-fixture"),
                       as: .image(
                           layout: .device(config: .iPhone13),
                           traits: UITraitCollection(userInterfaceStyle: .light),
                       ))
    }
}
