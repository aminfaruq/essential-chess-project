//
//  ECODetector.swift
//  EssentialChess
//

import Foundation

public final class ECODetector {
    private let database: [String: ECOOpening]
    
    public init(database: [String: ECOOpening]) {
        self.database = database
    }
    
    public func detect(fen: String) -> ECOOpening? {
        // Strip the half-move clock and full-move number if present
        let fenParts = fen.split(separator: " ")
        guard fenParts.count >= 4 else { return nil }
        
        let strippedFEN = fenParts.prefix(4).joined(separator: " ")
        return database[strippedFEN]
    }
}
