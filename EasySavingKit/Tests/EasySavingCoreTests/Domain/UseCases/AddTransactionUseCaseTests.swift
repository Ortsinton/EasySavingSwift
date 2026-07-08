//
//  AddTransactionUseCaseTests.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 8/7/26.
//

import EasySavingCore
import Testing

struct AddTransactionUseCaseTests {
    @Test(arguments: [0, -1])
    func `adding a zero transaction or a negative transaction throws a nonPositiveAmount error`(minorUnits: Int) async {
        let fakeTransactionRepository = FakeTransactionRepository()
        let category = Fixtures.makeCategory(id: Category.ID())
        let fakeCategoryRepository = FakeCategoryRepository(categories: [category])
        let money = Money(minorUnits: minorUnits, currencyCode: "EUR")
        let transaction = Fixtures.makeTransaction(amount: money, categoryID: category.id)
        let sut = AddTransactionUseCase(
            transactionRepository: fakeTransactionRepository,
            categoryRepository: fakeCategoryRepository
        )

        await #expect(throws: AddTransactionError.nonPositiveAmount) {
            try await sut.execute(transaction)
        }
        #expect(await fakeTransactionRepository.saved.isEmpty)
    }

    @Test
    func `adding a transaction with an incorrect category throws a categoryNotFound error`() async {
        let fakeTransactionRepository = FakeTransactionRepository()
        let fakeCategoryRepository = FakeCategoryRepository(categories: [Fixtures.makeCategory(id: Category.ID())])
        let categoryID = Category.ID()
        let transaction = Fixtures.makeTransaction(categoryID: categoryID)
        let sut = AddTransactionUseCase(
            transactionRepository: fakeTransactionRepository,
            categoryRepository: fakeCategoryRepository
        )

        await #expect(throws: AddTransactionError.categoryNotFound(categoryID)) {
            try await sut.execute(transaction)
        }
        #expect(await fakeTransactionRepository.saved.isEmpty)
    }

    @Test
    func `a valid transaction is saved in the repository`() async throws {
        let categoryID = Category.ID()
        let fakeTransactionRepository = FakeTransactionRepository()
        let fakeCategoryRepository = FakeCategoryRepository(categories: [Fixtures.makeCategory(id: categoryID)])
        let sut = AddTransactionUseCase(
            transactionRepository: fakeTransactionRepository,
            categoryRepository: fakeCategoryRepository
        )

        let transaction = Fixtures.makeTransaction(categoryID: categoryID)
        try await sut.execute(transaction)

        #expect(await fakeTransactionRepository.saved.count == 1)
        #expect(await fakeTransactionRepository.saved[0] == transaction)
    }
}
