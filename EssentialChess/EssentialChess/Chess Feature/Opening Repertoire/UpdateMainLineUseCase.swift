//
//  UpdateMainLineUseCase.swift
//  EssentialChess
//

import Foundation

public protocol UpdateMainLineUseCase {
    /// Sets a node as the main line and demotes its siblings.
    func setAsMainLine(node: RepertoireNode) throws
}

public final class DefaultUpdateMainLineUseCase: UpdateMainLineUseCase {
    private let store: RepertoireStore
    
    public init(store: RepertoireStore) {
        self.store = store
    }
    
    public func setAsMainLine(node: RepertoireNode) throws {
        var updatedNode = node
        updatedNode.isMainLine = true
        try store.update(updatedNode)
        
        if let parentFen = node.parentFen {
            let siblings = try store.children(for: parentFen, category: node.openingCategory)
            for sibling in siblings where sibling.fen != node.fen && sibling.isMainLine {
                var updatedSibling = sibling
                updatedSibling.isMainLine = false
                try store.update(updatedSibling)
            }
        }
    }
}
