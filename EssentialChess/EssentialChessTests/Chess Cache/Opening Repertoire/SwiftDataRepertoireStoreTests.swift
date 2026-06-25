//
//  SwiftDataRepertoireStoreTests.swift
//  EssentialChessTests
//

import XCTest
import SwiftData
@testable import EssentialChess

final class SwiftDataRepertoireStoreTests: XCTestCase {
    
    @MainActor
    func test_insert_deliversNoErrorOnEmptyCache() throws {
        let sut = makeSUT()
        let nodes = [anyNode()]
        
        XCTAssertNoThrow(try sut.insert(nodes))
        XCTAssertEqual(try sut.fetchCount(), 1)
    }
    
    @MainActor
    func test_nodeForFen_returnsNilWhenNodeDoesNotExist() throws {
        let sut = makeSUT()
        
        let retrieved = try sut.node(for: "invalid-fen", category: "Sicilian")
        XCTAssertNil(retrieved)
    }
    
    @MainActor
    func test_nodeForFen_returnsNodeWhenItExists() throws {
        let sut = makeSUT()
        let node = anyNode()
        
        try sut.insert([node])
        
        let retrieved = try sut.node(for: node.fen, category: node.openingCategory)
        XCTAssertEqual(retrieved, node)
    }
    
    @MainActor
    func test_childrenForParentFen_returnsChildren() throws {
        let sut = makeSUT()
        
        let parent1 = anyNode(fen: "parent1")
        let parent2 = anyNode(fen: "parent2")
        let child1 = anyNode(fen: "child1", parentFen: "parent1")
        let child2 = anyNode(fen: "child2", parentFen: "parent1")
        let child3 = anyNode(fen: "child3", parentFen: "parent2")
        
        try sut.insert([parent1, parent2, child1, child2, child3])
        
        let retrieved1 = try sut.children(for: "parent1", category: "Sicilian")
        XCTAssertEqual(Set(retrieved1), Set([child1, child2]))
        
        let retrieved2 = try sut.children(for: "parent2", category: "Sicilian")
        XCTAssertEqual(retrieved2, [child3])
    }
    
    @MainActor
    func test_childrenForParentFen_scopedByCategory() throws {
        let sut = makeSUT()
        
        let childA = anyNode(fen: "childA", parentFen: "root", category: "Italian")
        let childB = anyNode(fen: "childB", parentFen: "root", category: "Ruy Lopez")
        
        try sut.insert([childA, childB])
        
        let italianChildren = try sut.children(for: "root", category: "Italian")
        XCTAssertEqual(italianChildren, [childA])
        
        let ruyChildren = try sut.children(for: "root", category: "Ruy Lopez")
        XCTAssertEqual(ruyChildren, [childB])
    }
    
    @MainActor
    func test_sameFenDifferentCategories_bothStored() throws {
        let sut = makeSUT()
        
        let nodeA = anyNode(fen: "sameFen", category: "Italian (White)")
        let nodeB = anyNode(fen: "sameFen", category: "Italian (Black)")
        
        try sut.insert([nodeA, nodeB])
        
        XCTAssertEqual(try sut.fetchCount(), 2)
        XCTAssertNotNil(try sut.node(for: "sameFen", category: "Italian (White)"))
        XCTAssertNotNil(try sut.node(for: "sameFen", category: "Italian (Black)"))
    }
    
    @MainActor
    func test_update_modifiesExistingNode() throws {
        let sut = makeSUT()
        var node = anyNode()
        
        try sut.insert([node])
        
        node.isMainLine = true
        node.interval = 5
        
        try sut.update(node)
        
        let retrieved = try sut.node(for: node.fen, category: node.openingCategory)
        XCTAssertEqual(retrieved?.isMainLine, true)
        XCTAssertEqual(retrieved?.interval, 5)
    }
    
    @MainActor
    func test_fetchOpeningCategories_returnsRootNodes() throws {
        let sut = makeSUT()
        
        let root = anyNode(fen: "rootFen", parentFen: nil, category: "Italian (White)")
        let child = anyNode(fen: "childFen", parentFen: "rootFen", category: "Italian (White)")
        
        try sut.insert([root, child])
        
        let categories = try sut.fetchOpeningCategories()
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories.first?.fen, "rootFen")
        XCTAssertEqual(categories.first?.orientation, "Black") // colorToMove from the node
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func makeSUT() -> SwiftDataRepertoireStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: SwiftDataRepertoireNode.self, configurations: config)
        let context = ModelContext(container)
        return SwiftDataRepertoireStore(context: context)
    }
    
    private func anyNode(fen: String = UUID().uuidString, parentFen: String? = nil, category: String = "Sicilian") -> RepertoireNode {
        return RepertoireNode(
            fen: fen,
            movePlayed: "e4",
            uciMove: "e2e4",
            colorToMove: "Black",
            parentFen: parentFen,
            openingCategory: category,
            isMainLine: false,
            interval: 0,
            repetitions: 0,
            easeFactor: 2.5,
            nextReviewDate: nil
        )
    }
}
