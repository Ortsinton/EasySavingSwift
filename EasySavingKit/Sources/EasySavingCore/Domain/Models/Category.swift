//
//  Category.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 7/7/26.
//

import Foundation

public struct Category : Identifiable, Hashable {
    public struct ID: Sendable, Hashable {
        let uuid: UUID
    }
    
    public let id: ID
    public let name: String
    public let iconKey: String
    public let colorKey: String
}
