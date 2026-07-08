//
//  DeleteTransactionUseCase.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 8/7/26.
//

public struct DeleteTransactionUseCase: Sendable {
    private let repository: any TransactionRepository

    public init(repository: any TransactionRepository) {
        self.repository = repository
    }

    public func execute(_ transactionId: Transaction.ID) async throws {
        try await repository.delete(transactionId)
    }
}
