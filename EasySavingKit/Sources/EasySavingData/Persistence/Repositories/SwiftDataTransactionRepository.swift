//
//  SwiftDataTransactionRepository.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 13/7/26.
//

import EasySavingCore
import Foundation
import SwiftData

@ModelActor
actor SwiftDataTransactionRepository: TransactionRepository {
    func transactions() async throws -> [Transaction] {
        let descriptor = FetchDescriptor<TransactionModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse),
                     SortDescriptor(\.createdAt, order: .reverse)],
        )

        let result = try modelContext.fetch(descriptor)

        return try result.map { try $0.toDomain() }
    }

    func save(_ transaction: Transaction) async throws {
        if let existing = try existingTransactionModel(with: transaction.id) {
            existing.update(from: transaction)
        } else {
            modelContext.insert(TransactionModel(from: transaction))
        }
        try modelContext.save()
    }

    func delete(_ id: Transaction.ID) async throws {
        if let existing = try existingTransactionModel(with: id) {
            modelContext.delete(existing)
        }
        try modelContext.save()
    }

    private func existingTransactionModel(with id: Transaction.ID) throws -> TransactionModel? {
        let rawID = id.rawValue
        var descriptor = FetchDescriptor<TransactionModel>(
            predicate: #Predicate { $0.id == rawID },
        )

        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first
    }
}
