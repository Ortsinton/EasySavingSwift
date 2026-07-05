//
//  Test.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 5/7/26.
//

import Testing
@testable import EasySavingCore

struct CorePlaceholderTests {
    @Test func placeholderExposesText() async throws {
        #expect(CorePlaceholder().text == "Core Linked")
    }
}
