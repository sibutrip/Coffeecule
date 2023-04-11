//
//  Person.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 1/27/23.
//

import Foundation
import CloudKit

public struct Person: Codable, Identifiable {

    /// Properties
    public let id = UUID()
    let name: String
    var isPresent = true
    var coffeesOwed: [String: Int] = [:]
    
    /// Coding Key
    private enum CodingKeys: String, CodingKey {
        case name, isPresent, coffeesOwed
    }
    
    /// Initializer
    init(name: String) {
        self.name = name
    }
    
    /// Initializer when decoding from JSON
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        isPresent = try values.decode(Bool.self, forKey: .isPresent)
        coffeesOwed = try values.decode([String: Int].self, forKey: .coffeesOwed)
    }
}

/// Need for displayedDebts dictionary in ViewModel
extension Person: Hashable {
    public static func == (lhs: Person, rhs: Person) -> Bool {
        lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension Person: Comparable {
    public static func < (lhs: Person, rhs: Person) -> Bool {
        lhs.name < rhs.name
    }
}
