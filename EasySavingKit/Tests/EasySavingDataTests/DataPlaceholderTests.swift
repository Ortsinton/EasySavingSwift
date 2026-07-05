//
//  DataPlaceholderTests.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 5/7/26.
//

@testable import EasySavingData
import Testing

struct Test {
    @Test func `placeholder exposes text`() {
        #expect(DataPlaceholder().text == "Core Linked - Data linked")
    }
}
