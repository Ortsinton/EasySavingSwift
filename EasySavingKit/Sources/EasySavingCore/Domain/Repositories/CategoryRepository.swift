//
//  CategoryRepository.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 8/7/26.
//

public protocol CategoryRepository: Sendable {
    func categories() async throws -> [Category]
    func category(for id: Category.ID) async throws -> Category?
}
