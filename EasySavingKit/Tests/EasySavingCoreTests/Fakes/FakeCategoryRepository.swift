//
//  FakeCategoryRepository.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 8/7/26.
//

import EasySavingCore

struct FakeCategoryRepository: CategoryRepository {
    private let savedCategories: [Category]

    init(categories: [Category] = []) {
        savedCategories = categories
    }

    func categories() async throws -> [Category] {
        savedCategories
    }

    func category(for id: Category.ID) async throws -> Category? {
        savedCategories.first(where: { $0.id == id })
    }
}
