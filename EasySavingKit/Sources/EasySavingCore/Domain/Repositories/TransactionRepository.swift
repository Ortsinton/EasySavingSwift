//
//  TransactionRepository.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 8/7/26.
//

/// Save works as upsert. So it either adds or modifies if the entry already exists
public protocol TransactionRepository: Sendable {
    func transactions() async throws -> [Transaction]
    func save(_ transaction: Transaction) async throws
    func delete(_ id: Transaction.ID) async throws
}
