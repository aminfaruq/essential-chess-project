//
//  ECOOpening.swift
//  EssentialChess
//

import Foundation

public struct ECOOpening: Equatable {
    public let eco: String
    public let name: String
    
    public init(eco: String, name: String) {
        self.eco = eco
        self.name = name
    }
}
