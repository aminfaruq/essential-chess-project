//
//  PuzzleValidatorTests.swift
//  ChessBoardTests
//

import XCTest
@testable import ChessBoard

final class PuzzleValidatorTests: XCTestCase {

    func test_init_isNotCompleted() {
        let sut = makeSUT(moves: ["e2e4"])

        XCTAssertFalse(sut.isCompleted)
        XCTAssertEqual(sut.currentIndex, 0)
    }

    func test_validate_correctMove_advancesIndex() {
        let sut = makeSUT(moves: ["e2e4", "e7e5"])

        XCTAssertTrue(sut.validate(move: "e2e4"))
        XCTAssertEqual(sut.currentIndex, 1)
    }

    func test_validate_wrongMove_doesNotAdvance() {
        let sut = makeSUT(moves: ["e2e4"])

        XCTAssertFalse(sut.validate(move: "d2d4"))
        XCTAssertEqual(sut.currentIndex, 0)
    }

    func test_validate_afterCompleted_returnsFalse() {
        let sut = makeSUT(moves: ["e2e4"])

        _ = sut.validate(move: "e2e4")

        XCTAssertTrue(sut.isCompleted)
        XCTAssertFalse(sut.validate(move: "e7e5"))
    }

    func test_validate_handlesPromotionPrefix() {
        let sut = makeSUT(moves: ["e7e8q"])

        XCTAssertTrue(sut.validate(move: "e7e8"))
        XCTAssertTrue(sut.isCompleted)
    }

    func test_consumeNextMove_advancesAndReturnsMove() {
        let sut = makeSUT(moves: ["e2e4", "e7e5"])

        XCTAssertEqual(sut.consumeNextMove(), "e2e4")
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.consumeNextMove(), "e7e5")
        XCTAssertTrue(sut.isCompleted)
    }

    func test_consumeNextMove_afterCompleted_returnsNil() {
        let sut = makeSUT(moves: ["e2e4"])

        _ = sut.consumeNextMove()

        XCTAssertNil(sut.consumeNextMove())
    }

    func test_peekNextMove_doesNotAdvanceIndex() {
        let sut = makeSUT(moves: ["e2e4", "e7e5"])

        XCTAssertEqual(sut.peekNextMove(), "e2e4")
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.peekNextMove(), "e2e4")
    }

    func test_peekNextMove_afterCompleted_returnsNil() {
        let sut = makeSUT(moves: ["e2e4"])

        _ = sut.consumeNextMove()

        XCTAssertNil(sut.peekNextMove())
    }

    // MARK: - Helpers

    private func makeSUT(moves: [String], file: StaticString = #filePath, line: UInt = #line) -> PuzzleValidator {
        let sut = PuzzleValidator(expectedMoves: moves)
        addTeardownBlock { [weak sut] in
            XCTAssertNil(sut, "Memory leak", file: file, line: line)
        }
        return sut
    }
}
