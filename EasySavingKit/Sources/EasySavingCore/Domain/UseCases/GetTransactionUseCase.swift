//
//  GetTransactionUseCase.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 8/7/26.
//

public struct GetTransactionUseCase: Sendable {
    private let repository: any TransactionRepository

    public init(repository: TransactionRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [Transaction] {
        try await repository.transactions()
    }
}
