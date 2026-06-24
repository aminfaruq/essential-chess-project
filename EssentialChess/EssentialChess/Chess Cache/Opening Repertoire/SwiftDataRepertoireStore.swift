//
//  SwiftDataRepertoireStore.swift
//  EssentialChess
//

import Foundation
import SwiftData

public final class SwiftDataRepertoireStore: RepertoireStore {
    private let context: ModelContext
    
    public init(context: ModelContext) {
        self.context = context
    }
    
    public func insert(_ nodes: [RepertoireNode]) throws {
        for node in nodes {
            let model = SwiftDataRepertoireNode(
                fen: node.fen,
                movePlayed: node.movePlayed,
                uciMove: node.uciMove,
                colorToMove: node.colorToMove,
                parentFen: node.parentFen,
                openingCategory: node.openingCategory,
                isMainLine: node.isMainLine,
                interval: node.interval,
                repetitions: node.repetitions,
                easeFactor: node.easeFactor,
                nextReviewDate: node.nextReviewDate
            )
            context.insert(model)
        }
        try context.save()
    }
    
    public func node(for fen: String) throws -> RepertoireNode? {
        var descriptor = FetchDescriptor<SwiftDataRepertoireNode>(predicate: #Predicate { $0.fen == fen })
        descriptor.fetchLimit = 1
        let models = try context.fetch(descriptor)
        return models.first?.local
    }
    
    public func children(for parentFen: String) throws -> [RepertoireNode] {
        let pf: String? = parentFen
        let descriptor = FetchDescriptor<SwiftDataRepertoireNode>(predicate: #Predicate { $0.parentFen == pf })
        let models = try context.fetch(descriptor)
        return models.map { $0.local }
    }
    
    public func update(_ node: RepertoireNode) throws {
        let fen = node.fen
        var descriptor = FetchDescriptor<SwiftDataRepertoireNode>(predicate: #Predicate { $0.fen == fen })
        descriptor.fetchLimit = 1
        if let model = try context.fetch(descriptor).first {
            model.update(from: node)
            try context.save()
        }
    }
    
    public func fetchCount() throws -> Int {
        let descriptor = FetchDescriptor<SwiftDataRepertoireNode>()
        return try context.fetchCount(descriptor)
    }
}
