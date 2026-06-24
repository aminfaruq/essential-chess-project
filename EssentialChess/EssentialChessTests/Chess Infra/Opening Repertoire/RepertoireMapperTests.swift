//
//  RepertoireMapperTests.swift
//  EssentialChessTests
//

import XCTest
@testable import EssentialChess

final class RepertoireMapperTests: XCTestCase {
    
    func test_map_throwsErrorOnInvalidJSON() {
        let invalidJSON = Data("invalid json".utf8)
        
        XCTAssertThrowsError(try RepertoireMapper.map(invalidJSON))
    }
    
    func test_map_deliversEmptyListOnEmptyJSONList() throws {
        let emptyJSON = Data("[]".utf8)
        
        let nodes = try RepertoireMapper.map(emptyJSON)
        XCTAssertTrue(nodes.isEmpty)
    }
    
    func test_map_deliversNodesOnValidJSON() throws {
        let json = """
        [
            {
                "fen": "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1",
                "movePlayed": "e4",
                "uci": "e2e4",
                "colorToMove": "Black",
                "parentFen": "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                "openingCategory": "King's Pawn Game"
            }
        ]
        """.data(using: .utf8)!
        
        let nodes = try RepertoireMapper.map(json)
        
        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].fen, "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1")
        XCTAssertEqual(nodes[0].movePlayed, "e4")
        XCTAssertEqual(nodes[0].uciMove, "e2e4")
        XCTAssertEqual(nodes[0].colorToMove, "Black")
        XCTAssertEqual(nodes[0].parentFen, "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
        XCTAssertEqual(nodes[0].openingCategory, "King's Pawn Game")
    }
}
