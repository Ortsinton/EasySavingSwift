//
//  SwiftDataCategoryRepositoryTests.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 13/7/26.
//

@testable import EasySavingData
import Foundation
import SwiftData
import Testing

struct SwiftDataCategoryRepositoryTests {
    let container: ModelContainer
    let repository: SwiftDataCategoryRepository

    init() throws {
        container = try ModelContainer(
            for: TransactionModel.self, CategoryModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true),
        )
        repository = SwiftDataCategoryRepository(modelContainer: container)
    }

    @Test func `categories are always returned alphabetically`() async throws {
        let category1 = Fixtures.makeCategory(name: "A categor")
        let category2 = Fixtures.makeCategory(name: "better category")
        let category3 = Fixtures.makeCategory(name: "Category 3")
        let category4 = Fixtures.makeCategory(name: "yet another category")

        try seed([
            CategoryModel(from: category3),
            CategoryModel(from: category4),
            CategoryModel(from: category1),
            CategoryModel(from: category2),
        ])

        let categories = try await repository.categories()

        #expect(categories == [category1, category2, category3, category4])
    }

    @Test func `fetching an existing id returns it`() async throws {
        let id = Category.ID()
        let expectedCategory = Fixtures.makeCategory(id: id)

        try seed([CategoryModel(from: expectedCategory)])

        let actualCategory = try await repository.category(for: expectedCategory.id)

        #expect(try #require(actualCategory) == expectedCategory)
    }

    @Test func `fetching a non existing id returns nil`() async throws {
        let existingID = Category.ID()
        let nonExistingID = Category.ID()
        let expectedCategory = Fixtures.makeCategory(id: existingID)

        try seed([CategoryModel(from: expectedCategory)])

        let actualCategory = try await repository.category(for: nonExistingID)

        #expect(actualCategory == nil)
    }

    private func seed(_ models: [CategoryModel]) throws {
        let context = ModelContext(container)
        for model in models {
            context.insert(model)
        }
        try context.save()
    }
}
