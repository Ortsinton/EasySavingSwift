//
//  TransactionRepository.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 8/7/26.
//

public protocol TransactionRepository: Sendable {
    /// Returns all transactions sorted by business date (newest first); ties are broken by creation date
    func transactions() async throws -> [Transaction]
    /// Save works as upsert. So it either adds or modifies if the entry already exists
    func save(_ transaction: Transaction) async throws
    /// Deletes the transaction with the given id; deleting a non-existent id is a no-op
    func delete(_ id: Transaction.ID) async throws
}
