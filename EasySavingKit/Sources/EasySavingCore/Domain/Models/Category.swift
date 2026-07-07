//
//  Category.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 7/7/26.
//

import Foundation

public struct Category: Sendable, Identifiable, Hashable {
    public struct ID: Sendable, Hashable {
        public let rawValue: UUID
        
        public init(rawValue: UUID = UUID()) {
            self.rawValue = rawValue
        }
    }

    public let id: ID
    public let name: String
    public let iconKey: String
    public let colorKey: String
}
