//
//  GetTransactionsUseCaseTests.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 8/7/26.
//
import EasySavingCore
import Testing

struct GetTransactionsUseCaseTests {
    @Test
    func `when there are transactions stored it returns them`() async throws {
        let fakeRepository = FakeTransactionRepository()
        let sut = GetTransactionsUseCase(repository: fakeRepository)
        let transaction = Fixtures.makeTransaction()

        try await fakeRepository.save(transaction)

        let transactions = try await sut.execute()

        #expect(transactions.count == 1)
        #expect(transactions[0] == transaction)
    }

    @Test
    func `when there are no transactions it returns an empty list`() async throws {
        let fakeRepository = FakeTransactionRepository()
        let sut = GetTransactionsUseCase(repository: fakeRepository)

        let transactions = try await sut.execute()
        #expect(transactions.isEmpty)
    }
}
