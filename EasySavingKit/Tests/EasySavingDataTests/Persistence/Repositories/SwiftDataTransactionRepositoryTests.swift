//
//  SwiftDataTransactionRepositoryTests.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 13/7/26.
//

import EasySavingCore
@testable import EasySavingData
import SwiftData
import Testing

struct SwiftDataTransactionRepositoryTests {
    let container: ModelContainer
    let repository: SwiftDataTransactionRepository

    init() throws {
        container = try ModelContainer(
            for: TransactionModel.self, CategoryModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true),
        )
        repository = SwiftDataTransactionRepository(modelContainer: container)
    }

    @Test func `if there are no values stored it returns []`() async throws {
        await #expect(try repository.transactions().isEmpty)
    }

    @Test func `saving a transaction stores it and it's returned later`() async throws {
        let transaction = Fixtures.makeTransaction()
        try await repository.save(transaction)

        let fetchedTransaction = try await repository.transactions()
        #expect(fetchedTransaction.count == 1)
        #expect(fetchedTransaction[0] == transaction)
    }

    @Test func `saving a transaction twice with different fields returns the second one stored`() async throws {
        let transaction = Fixtures.makeTransaction()
        try await repository.save(transaction)

        let overlappingTransaction = Fixtures.makeTransaction(id: transaction.id, note: "This is a modified note")
        try await repository.save(overlappingTransaction)

        let fetchedTransaction = try await repository.transactions()
        #expect(fetchedTransaction.count == 1)
        #expect(fetchedTransaction[0] == overlappingTransaction)
    }

    @Test func `inserting two different transactions gives back both`() async throws {
        let transaction = Fixtures.makeTransaction()
        let transaction2 = Fixtures.makeTransaction()
        try await repository.save(transaction)
        try await repository.save(transaction2)

        let fetchedTransactions = try await repository.transactions()
        #expect(fetchedTransactions.count == 2)
        #expect(fetchedTransactions.contains(transaction))
        #expect(fetchedTransactions.contains(transaction2))
    }

    @Test func `transactions are sorted by date first and createdAt second`() async throws {
        let oldestDate = Fixtures.date(2026, 7, 12)
        let newestDate = Fixtures.date(2026, 7, 13)
        let newestCreatedAt = Fixtures.date(2026, 7, 13, 16, 57)
        let oldestCreatedAt = Fixtures.date(2026, 7, 13, 16, 58)
        let firstTransaction = Fixtures.makeTransaction(date: newestDate, createdAt: oldestCreatedAt)
        let secondTransaction = Fixtures.makeTransaction(date: newestDate, createdAt: newestCreatedAt)
        let thirdTransaction = Fixtures.makeTransaction(date: oldestDate)

        try await repository.save(thirdTransaction)
        try await repository.save(firstTransaction)
        try await repository.save(secondTransaction)

        let fetchedTransactions = try await repository.transactions()
        #expect(fetchedTransactions.count == 3)
        #expect(fetchedTransactions == [firstTransaction, secondTransaction, thirdTransaction])
    }

    @Test func `deleting twice removes it once and is a no-op the second time`() async throws {
        let id = Transaction.ID()
        let transaction = Fixtures.makeTransaction(id: id)
        try await repository.save(transaction)

        var fetchedTransactions = try await repository.transactions()
        #expect(fetchedTransactions.count == 1)

        try await repository.delete(id)
        fetchedTransactions = try await repository.transactions()
        #expect(fetchedTransactions.isEmpty)

        try await repository.delete(id)
        fetchedTransactions = try await repository.transactions()
        #expect(fetchedTransactions.isEmpty)
    }
}
