//
//  Test.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 5/7/26.
//

import Testing
@testable import EasySavingData

struct Test {
    @Test func placeholderExposesText() async throws {
        #expect(DataPlaceholder().text == "Core Linked - Data linked")
    }
}
