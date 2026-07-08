//
//  AddTransactionUseCase.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 8/7/26.
//

public enum AddTransactionError: Error, Equatable {
    case nonPositiveAmount
    case categoryNotFound(Category.ID)
}

public struct AddTransactionUseCase: Sendable {
    private let transactionRepository: any TransactionRepository
    private let categoryRepository: any CategoryRepository

    public init(transactionRepository: any TransactionRepository, categoryRepository: any CategoryRepository) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
    }

    public func execute(_ transaction: Transaction) async throws {
        guard transaction.amount.minorUnits > 0 else {
            throw AddTransactionError.nonPositiveAmount
        }

        guard try await categoryRepository.category(for: transaction.categoryID) != nil else {
            throw AddTransactionError.categoryNotFound(transaction.categoryID)
        }

        try await transactionRepository.save(transaction)
    }
}
