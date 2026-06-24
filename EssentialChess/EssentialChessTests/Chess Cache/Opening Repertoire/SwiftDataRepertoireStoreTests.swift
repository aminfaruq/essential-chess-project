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
        
        let retrieved = try sut.node(for: "invalid-fen")
        XCTAssertNil(retrieved)
    }
    
    @MainActor
    func test_nodeForFen_returnsNodeWhenItExists() throws {
        let sut = makeSUT()
        let node = anyNode()
        
        try sut.insert([node])
        
        let retrieved = try sut.node(for: node.fen)
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
        
        let retrieved1 = try sut.children(for: "parent1")
        XCTAssertEqual(Set(retrieved1), Set([child1, child2]))
        
        let retrieved2 = try sut.children(for: "parent2")
        XCTAssertEqual(retrieved2, [child3])
    }
    
    @MainActor
    func test_update_modifiesExistingNode() throws {
        let sut = makeSUT()
        var node = anyNode()
        
        try sut.insert([node])
        
        node.isMainLine = true
        node.interval = 5
        
        try sut.update(node)
        
        let retrieved = try sut.node(for: node.fen)
        XCTAssertEqual(retrieved?.isMainLine, true)
        XCTAssertEqual(retrieved?.interval, 5)
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func makeSUT() -> SwiftDataRepertoireStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: SwiftDataRepertoireNode.self, configurations: config)
        let context = ModelContext(container)
        return SwiftDataRepertoireStore(context: context)
    }
    
    private func anyNode(fen: String = UUID().uuidString, parentFen: String? = nil) -> RepertoireNode {
        return RepertoireNode(
            fen: fen,
            movePlayed: "e4",
            uciMove: "e2e4",
            colorToMove: "Black",
            parentFen: parentFen,
            openingCategory: "Sicilian",
            isMainLine: false,
            interval: 0,
            repetitions: 0,
            easeFactor: 2.5,
            nextReviewDate: nil
        )
    }
}
