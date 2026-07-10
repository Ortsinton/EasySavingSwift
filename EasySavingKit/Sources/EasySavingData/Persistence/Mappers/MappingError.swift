//
//  MappingError.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 10/7/26.
//

enum MappingError: Error, Equatable {
    case unknownTransactionKind(String)
}
