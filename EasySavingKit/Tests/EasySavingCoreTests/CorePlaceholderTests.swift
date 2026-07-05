//
//  CorePlaceholderTests.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 5/7/26.
//

@testable import EasySavingCore
import Testing

struct CorePlaceholderTests {
    @Test func `placeholder exposes text`() {
        #expect(CorePlaceholder().text == "Core Linked")
    }
}
