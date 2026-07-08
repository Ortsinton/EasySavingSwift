//
//  DeleteTransactionUseCaseTests.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 8/7/26.
//
import EasySavingCore
import Testing

struct DeleteTransactionUseCaseTests {
    @Test
    func `deleting a transaction removes only that transaction`() async throws {
        let fakeRepository = FakeTransactionRepository()
        let useCase = DeleteTransactionUseCase(repository: fakeRepository)
        let transactionId = Transaction.ID()
        let transaction = Fixtures.makeTransaction(id: transactionId)
        let expectedTransaction = Fixtures.makeTransaction()

        try await fakeRepository.save(transaction)
        try await fakeRepository.save(expectedTransaction)
        await #expect(throws: Never.self) {
            try await useCase.execute(transactionId)
        }

        #expect(await fakeRepository.saved.count == 1)
        #expect(await fakeRepository.saved[0] == expectedTransaction)
    }

    @Test
    func `deleting a transaction that does not exist does nothing`() async throws {
        let fakeRepository = FakeTransactionRepository()
        let expectedTransaction = Fixtures.makeTransaction()
        try await fakeRepository.save(expectedTransaction)

        let useCase = DeleteTransactionUseCase(repository: fakeRepository)

        await #expect(throws: Never.self) {
            try await useCase.execute(Transaction.ID())
        }
        #expect(await fakeRepository.saved.count == 1)
        #expect(await fakeRepository.saved[0] == expectedTransaction)
    }
}
