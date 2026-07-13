//
//  SwiftDataCategoryRepository.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 13/7/26.
//

import SwiftData
import EasySavingCore
import Foundation

@ModelActor
actor SwiftDataCategoryRepository: CategoryRepository {
    func categories() async throws -> [Category] {
        let descriptor = FetchDescriptor<CategoryModel>(
            sortBy: [SortDescriptor(\.name, comparator: .localizedStandard, order: .forward)],
        )

        let result = try modelContext.fetch(descriptor)

        return result.map { $0.toDomain() }
    }
    
    func category(for id: Category.ID) async throws -> Category? {
        let rawID = id.rawValue
        var descriptor = FetchDescriptor<CategoryModel>(
            predicate: #Predicate {
                $0.id == rawID
            }
        )
        descriptor.fetchLimit = 1
        
        return try modelContext.fetch(descriptor).first?.toDomain()
    }
}
