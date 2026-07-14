//
//  PersistenceFactory.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 14/7/26.
//

import SwiftData
import EasySavingCore

public enum PersistenceFactory {
    
    public static func makeModelContainer() throws -> ModelContainer {
        try ModelContainer(
            for: TransactionModel.self, CategoryModel.self,
            configurations: ModelConfiguration("EasySaving")
        )
    }
    
    public static func makeTransactionRepository(container: ModelContainer) -> any TransactionRepository {
        SwiftDataTransactionRepository(modelContainer: container)
    }
    
    public static func makeCategoryRepository(container: ModelContainer) -> any CategoryRepository {
        SwiftDataCategoryRepository(modelContainer: container)
    }
}
