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
        self.savedCategories = categories
    }
    
    func categories() async throws -> [Category] {
        return savedCategories
    }
    
    func category(for id: Category.ID) async throws -> Category? {
        return savedCategories.first(where: { $0.id == id })
    }
}
