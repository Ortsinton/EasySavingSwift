//
//  CategoryModelMappingTests.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 10/7/26.
//

import EasySavingCore
@testable import EasySavingData
import Foundation
import Testing

struct CategoryModelMappingTests {
    @Test
    func `category round trip provides the exact same fields`() {
        let expectedID = UUID()
        let expectedName = "Test Category"
        let expectedIconKey = "test-icon"
        let expecteColorKey = "test-color"
        let category = Category(
            id: Category.ID(rawValue: expectedID),
            name: expectedName,
            iconKey: expectedIconKey,
            colorKey: expecteColorKey,
        )

        let model = CategoryModel(from: category)
        expectProperties(of: category, match: model)

        let actualCategory = model.toDomain()

        #expect(actualCategory == category)
    }

    private func expectProperties(of category: EasySavingCore.Category, match categoryModel: CategoryModel) {
        #expect(category.id.rawValue == categoryModel.id)
        #expect(category.name == categoryModel.name)
        #expect(category.iconKey == categoryModel.iconKey)
        #expect(category.colorKey == categoryModel.colorKey)
    }
}
