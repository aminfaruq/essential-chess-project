//
//  CloudEvaluation.swift
//  EssentialChess
//

import Foundation

public struct CloudEvaluation: Hashable, Equatable {
    public let fen: String
    public let depth: Int
    public let pvs: [PrincipalVariation]
    
    public init(fen: String, depth: Int, pvs: [PrincipalVariation]) {
        self.fen = fen
        self.depth = depth
        self.pvs = pvs
    }
}

public struct PrincipalVariation: Hashable, Equatable {
    public let moves: String // e.g. "e2e4 e7e5"
    public let cp: Int? // centipawns, nil if mate
    public let mate: Int? // moves to mate
    
    public init(moves: String, cp: Int?, mate: Int?) {
        self.moves = moves
        self.cp = cp
        self.mate = mate
    }
}
