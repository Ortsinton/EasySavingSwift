//
//  GetTransactionsUseCase.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 8/7/26.
//

public struct GetTransactionsUseCase: Sendable {
    private let repository: any TransactionRepository

    public init(repository: any TransactionRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [Transaction] {
        try await repository.transactions()
    }
}
