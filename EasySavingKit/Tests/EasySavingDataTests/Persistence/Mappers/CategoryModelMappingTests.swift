//
//  CategoryModelMappingTests.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 10/7/26.
//

import Testing
@testable import EasySavingData
import EasySavingCore
import Foundation

@Suite
struct CategoryModelMappingTests {
    
    @Test
    func `category round trip provides the exact same fields`() async throws {
        let expectedID = UUID()
        let expectedName = "Test Category"
        let expectedIconKey = "test-icon"
        let expecteColorKey = "test-color"
        let category = Category(
            id: Category.ID(rawValue: expectedID),
            name: expectedName,
            iconKey: expectedIconKey,
            colorKey: expecteColorKey
        )
        
        let model = CategoryModel(from: category)
        expectProperties(of:category, match: model)
        
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
