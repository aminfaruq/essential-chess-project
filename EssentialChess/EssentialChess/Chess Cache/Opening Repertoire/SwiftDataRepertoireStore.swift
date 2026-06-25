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
    
    public func node(for fen: String, category: String) throws -> RepertoireNode? {
        let descriptor = FetchDescriptor<SwiftDataRepertoireNode>(
            predicate: #Predicate { $0.fen == fen && $0.openingCategory == category }
        )
        let models = try context.fetch(descriptor)
        return models.first?.local
    }
    
    public func children(for parentFen: String, category: String) throws -> [RepertoireNode] {
        let pf: String? = parentFen
        let descriptor = FetchDescriptor<SwiftDataRepertoireNode>(
            predicate: #Predicate { $0.parentFen == pf && $0.openingCategory == category }
        )
        let models = try context.fetch(descriptor)
        return models.map { $0.local }
    }
    
    public func update(_ node: RepertoireNode) throws {
        let fen = node.fen
        let category = node.openingCategory
        let descriptor = FetchDescriptor<SwiftDataRepertoireNode>(
            predicate: #Predicate { $0.fen == fen && $0.openingCategory == category }
        )
        if let model = try context.fetch(descriptor).first {
            model.update(from: node)
            try context.save()
        }
    }
    
    public func fetchCount() throws -> Int {
        let descriptor = FetchDescriptor<SwiftDataRepertoireNode>()
        return try context.fetchCount(descriptor)
    }
    
    public func deleteAll() throws {
        try context.delete(model: SwiftDataRepertoireNode.self)
        try context.save()
    }
    
    public func fetchOpeningCategories() throws -> [OpeningCategoryPreview] {
        let descriptor = FetchDescriptor<SwiftDataRepertoireNode>(predicate: #Predicate { $0.parentFen == nil })
        let rootModels = try context.fetch(descriptor)
        
        // Each root node is a separate category entry.
        // Use colorToMove from root node as the orientation (which side the user plays).
        var seen: Set<String> = []
        var results: [OpeningCategoryPreview] = []
        
        for model in rootModels {
            let key = "\(model.openingCategory)_\(model.colorToMove)"
            if !seen.contains(key) {
                seen.insert(key)
                results.append(OpeningCategoryPreview(
                    categoryName: model.openingCategory,
                    fen: model.fen,
                    orientation: model.colorToMove
                ))
            }
        }
        
        return results.sorted(by: { $0.categoryName < $1.categoryName })
    }
    
    public func fetchNodes(forCategory categoryName: String) throws -> [RepertoireNode] {
        let descriptor = FetchDescriptor<SwiftDataRepertoireNode>(predicate: #Predicate { $0.openingCategory == categoryName })
        let models = try context.fetch(descriptor)
        return models.map { $0.local }
    }
}
