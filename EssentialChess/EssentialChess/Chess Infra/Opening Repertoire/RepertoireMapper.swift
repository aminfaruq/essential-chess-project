//
//  RepertoireMapper.swift
//  EssentialChess
//

import Foundation

public final class RepertoireMapper {
    private struct Root: Decodable {
        let fen: String
        let movePlayed: String
        let uci: String
        let colorToMove: String
        let parentFen: String?
        let openingCategory: String
        
        var node: RepertoireNode {
            return RepertoireNode(
                fen: fen,
                movePlayed: movePlayed,
                uciMove: uci,
                colorToMove: colorToMove,
                parentFen: parentFen,
                openingCategory: openingCategory
            )
        }
    }
    
    public enum Error: Swift.Error {
        case invalidData
    }
    
    public static func map(_ data: Data) throws -> [RepertoireNode] {
        guard let root = try? JSONDecoder().decode([Root].self, from: data) else {
            throw Error.invalidData
        }
        return root.map { $0.node }
    }
}
