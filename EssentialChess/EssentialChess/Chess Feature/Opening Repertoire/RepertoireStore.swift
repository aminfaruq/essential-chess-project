//
//  RepertoireStore.swift
//  EssentialChess
//

import Foundation

public protocol RepertoireStore {
    func insert(_ nodes: [RepertoireNode]) throws
    func node(for fen: String) throws -> RepertoireNode?
    func children(for parentFen: String) throws -> [RepertoireNode]
    func update(_ node: RepertoireNode) throws
    func fetchCount() throws -> Int
}
