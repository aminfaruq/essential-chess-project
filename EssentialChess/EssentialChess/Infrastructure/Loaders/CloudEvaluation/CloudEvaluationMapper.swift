//
//  CloudEvaluationMapper.swift
//  EssentialChess
//

import Foundation

public final class CloudEvaluationMapper {
    private struct Root: Decodable {
        let fen: String
        let depth: Int
        let pvs: [PVNode]
        
        var evaluation: CloudEvaluation {
            return CloudEvaluation(fen: fen, depth: depth, pvs: pvs.map { $0.pv })
        }
    }
    
    private struct PVNode: Decodable {
        let moves: String
        let cp: Int?
        let mate: Int?
        
        var pv: PrincipalVariation {
            return PrincipalVariation(moves: moves, cp: cp, mate: mate)
        }
    }
    
    public enum Error: Swift.Error {
        case invalidData
    }
    
    public static func map(_ data: Data, response: HTTPURLResponse) throws -> CloudEvaluation {
        guard response.statusCode == 200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw Error.invalidData
        }
        return root.evaluation
    }
}
