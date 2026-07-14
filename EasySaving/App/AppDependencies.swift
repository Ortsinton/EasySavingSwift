//
//  AppDependencies.swift
//  EasySaving
//
//  Created by Jorge Sirvent on 14/7/26.
//

import EasySavingData
import EasySavingCore

struct AppDependencies {
    let getTransactionsUseCase: GetTransactionsUseCase
    let addTransactionUseCase: AddTransactionUseCase
    let deleteTransactionUseCase: DeleteTransactionUseCase
    
    init() {
        do {
            let container = try PersistenceFactory.makeModelContainer()
            
            let categoryRepository = PersistenceFactory.makeCategoryRepository(container: container)
            let transactionRepository = PersistenceFactory.makeTransactionRepository(container: container)
            
            getTransactionsUseCase = GetTransactionsUseCase(repository: transactionRepository)
            addTransactionUseCase = AddTransactionUseCase(
                transactionRepository: transactionRepository,
                categoryRepository: categoryRepository
            )
            deleteTransactionUseCase = DeleteTransactionUseCase(repository: transactionRepository)
        } catch {
            fatalError("Could not create the persistent store: \(error)")
        }
    }
}
