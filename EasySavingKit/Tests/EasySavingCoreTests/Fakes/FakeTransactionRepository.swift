//
//  FakeTransactionRepository.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 8/7/26.
//

import EasySavingCore

actor FakeTransactionRepository: TransactionRepository {
    private(set) var saved: [Transaction] = []
    
    func transactions() async throws -> [Transaction] {
        return saved
    }
    
    func save(_ transaction: Transaction) async throws {
        if let index = saved.firstIndex(where: { $0.id == transaction.id }) {
            saved[index] = transaction
        }
        else {
            saved.append(transaction)
        }
    }
    
    func delete(_ id: Transaction.ID) async throws {
        saved.removeAll(where: { $0.id == id })
    }
}
