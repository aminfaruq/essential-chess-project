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
        let categoryName: String
        
        var node: RepertoireNode {
            return RepertoireNode(
                fen: fen,
                movePlayed: movePlayed,
                uciMove: uci,
                colorToMove: colorToMove,
                parentFen: parentFen,
                openingCategory: categoryName
            )
        }
    }
    
    public enum Error: Swift.Error {
        case invalidData
    }
    
    public static func map(_ data: Data) throws -> [RepertoireNode] {
        do {
            let root = try JSONDecoder().decode([Root].self, from: data)
            return root.map { $0.node }
        } catch {
            print("DECODING ERROR: \(error)")
            throw Error.invalidData
        }
    }
}
