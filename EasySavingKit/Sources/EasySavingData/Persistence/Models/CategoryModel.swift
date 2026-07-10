//
//  CategoryModel.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 9/7/26.
//

import Foundation
import SwiftData

@Model
final class CategoryModel {
    var id: UUID
    var name: String
    var colorKey: String
    var iconKey: String

    init(id: UUID, name: String, colorKey: String, iconKey: String) {
        self.id = id
        self.name = name
        self.colorKey = colorKey
        self.iconKey = iconKey
    }
}
