//
//  RepertoireStore.swift
//  EssentialChess
//

import Foundation

public struct OpeningCategoryPreview: Hashable, Equatable, Identifiable {
    public var id: String { "\(categoryName)_\(orientation)" }
    public let categoryName: String
    public let fen: String
    public let orientation: String // "White" or "Black"
    
    public init(categoryName: String, fen: String, orientation: String) {
        self.categoryName = categoryName
        self.fen = fen
        self.orientation = orientation
    }
}

public protocol RepertoireStore {
    func insert(_ nodes: [RepertoireNode]) throws
    func node(for fen: String, category: String) throws -> RepertoireNode?
    func children(for parentFen: String, category: String) throws -> [RepertoireNode]
    func update(_ node: RepertoireNode) throws
    func fetchCount() throws -> Int
    func fetchOpeningCategories() throws -> [OpeningCategoryPreview]
    func fetchNodes(forCategory categoryName: String) throws -> [RepertoireNode]
    func deleteAll() throws
}
