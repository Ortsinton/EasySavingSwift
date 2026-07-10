//
//  CategoryModel+Mapping.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 10/7/26.
//

import EasySavingCore

extension CategoryModel {
    convenience init(from category: Category) {
        self.init(
            id: category.id.rawValue,
            name: category.name,
            colorKey: category.colorKey,
            iconKey: category.iconKey,
        )
    }

    func toDomain() -> Category {
        Category(
            id: Category.ID(rawValue: id),
            name: name,
            iconKey: iconKey,
            colorKey: colorKey,
        )
    }
}
