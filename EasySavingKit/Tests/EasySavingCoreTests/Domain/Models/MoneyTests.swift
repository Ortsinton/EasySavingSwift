//
//  MoneyTests.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 7/7/26.
//

import Testing
import EasySavingCore

@Suite
struct MoneyTests {
    @Test(arguments: [
        (a: 1000, b: 250, sum: 1250),           // normal case
        (a: 0, b: 0, sum: 0),                   // neutral
        (a: -500, b: 500, sum: 0),              // crossing by zero
        (a: -300, b: -700, sum: -1000),         // both negative
        (a: Int.max - 1, b: 1, sum: Int.max),   // top border without overflow
    ])
    
    func `addition preserves exact minor units`(a: Int, b: Int, sum: Int) {
        let result = Money(minorUnits: a, currencyCode: "USD") + Money(minorUnits: b, currencyCode: "USD")
        #expect(result == Money(minorUnits: sum, currencyCode: "USD"))
    }
    
    @Test(arguments: ["EUR", "USD", "JPY"])
    func `addition preserves currency`(currencyCode: String) {
        let result = Money(minorUnits: 1, currencyCode: currencyCode) + Money(minorUnits: 2, currencyCode: currencyCode)
        #expect(result.currencyCode == currencyCode)
    }
    
    @Test(arguments: [
        (a: 1000, b: 250, sub: 750),            // normal case
        (a: 250, b: 1000, sub: -750),           // negative case
        (a: 0, b: 0, sub: 0),                   // neutral
        (a: -500, b: 500, sub: -1000),          // subtracting to a negative number
        (a: -300, b: -700, sub: 400),           // both negative, positive result
        (a: Int.max-1, b: -1, sub: Int.max),   // top border without overflow
    ])
    
    func `subtraction preserves exact minor units`(a: Int, b: Int, sub: Int) {
        let result = Money(minorUnits: a, currencyCode: "USD") - Money(minorUnits: b, currencyCode: "USD")
        #expect(result == Money(minorUnits: sub, currencyCode: "USD"))
    }
    
    @Test(arguments: ["EUR", "USD", "JPY"])
    func `subtraction preserves currency`(currencyCode: String) {
        let result = Money(minorUnits: 1, currencyCode: currencyCode) - Money(minorUnits: 2, currencyCode: currencyCode)
        #expect(result.currencyCode == currencyCode)
    }
    
    @Test(arguments: [
        (amount: 1000, scalar: 250, mult: 250000),           // normal case
        (amount: 1000, scalar: 0, mult: 0),                       // multiply by zero
        (amount: -500, scalar: 500, mult: -250000),           // negative case
        (amount: -300, scalar: -700, mult: 210000),           // both negative, positive result
        (amount: Int.max, scalar: 1, mult: Int.max),     // top border without overflow
    ])
    
    func `multiplication preserves exact minor units`(amount: Int, scalar: Int, mult: Int) {
        let result = Money(minorUnits: amount, currencyCode: "USD") * scalar
        #expect(result == Money(minorUnits: mult, currencyCode: "USD"))
    }
    
    @Test(arguments: [
        (a: 1000, res: -1000),       // negating a positive
        (a: -40, res: 40),           // negating a negative case
        (a: 0, res: 0),              // negating zero
    ])
    func `negation preserves exact minor units`(a: Int, res: Int) {
        let result = -Money(minorUnits: a, currencyCode: "USD")
        #expect(result == Money(minorUnits: res, currencyCode: "USD"))
    }
}
