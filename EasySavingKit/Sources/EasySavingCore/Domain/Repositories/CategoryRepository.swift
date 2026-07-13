//
//  CategoryRepository.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 8/7/26.
//

public protocol CategoryRepository: Sendable {
    /// Returns all categories sorted alphabetically by name (locale-aware)
    func categories() async throws -> [Category]
    /// Returns the category that matches the provided ID if it exists.
    func category(for id: Category.ID) async throws -> Category?
}
