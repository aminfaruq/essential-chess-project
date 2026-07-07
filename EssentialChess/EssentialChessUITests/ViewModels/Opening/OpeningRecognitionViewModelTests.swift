//
//  OpeningRecognitionViewModelTests.swift
//  EssentialChessUITests
//

import XCTest
import EssentialChess
import EssentialChessUI

final class OpeningRecognitionViewModelTests: XCTestCase {

    // MARK: - Init Tests

    func test_init_setsDefaultStartingState() {
        let sut = makeSUT()

        XCTAssertEqual(sut.currentOpeningName, "Starting Position")
        XCTAssertEqual(sut.currentECO, "")
    }

    // MARK: - onMove Tests

    func test_onMove_updatesStateWhenOpeningIsFound() {
        let knownFEN = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -"
        let database = [knownFEN: ECOOpening(eco: "C20", name: "King's Pawn Game")]
        let sut = makeSUT(database: database)

        sut.onMove(resultingFen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2")

        XCTAssertEqual(sut.currentOpeningName, "King's Pawn Game")
        XCTAssertEqual(sut.currentECO, "C20")
    }

    func test_onMove_retainsPreviousStateWhenOpeningIsNotFound() {
        let knownFEN = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -"
        let database = [knownFEN: ECOOpening(eco: "C20", name: "King's Pawn Game")]
        let sut = makeSUT(database: database)

        sut.onMove(resultingFen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2")
        sut.onMove(resultingFen: "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 3")

        XCTAssertEqual(sut.currentOpeningName, "King's Pawn Game")
        XCTAssertEqual(sut.currentECO, "C20")
    }

    func test_onMove_retainsDefaultStateWhenFirstMoveNotInDatabase() {
        let database = [String: ECOOpening]()
        let sut = makeSUT(database: database)

        sut.onMove(resultingFen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2")

        XCTAssertEqual(sut.currentOpeningName, "Starting Position")
        XCTAssertEqual(sut.currentECO, "")
    }

    func test_onMove_resetsToStartingPositionWhenReachingInitialFen() {
        let knownFEN = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -"
        let database = [knownFEN: ECOOpening(eco: "C20", name: "King's Pawn Game")]
        let sut = makeSUT(database: database)

        sut.onMove(resultingFen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2")
        XCTAssertEqual(sut.currentOpeningName, "King's Pawn Game")

        sut.onMove(resultingFen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")

        XCTAssertEqual(sut.currentOpeningName, "Starting Position")
        XCTAssertEqual(sut.currentECO, "")
    }

    func test_onMove_resetsWhenFenHasInitialPrefixWithDifferentSideToMove() {
        let knownFEN = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -"
        let database = [knownFEN: ECOOpening(eco: "C20", name: "King's Pawn Game")]
        let sut = makeSUT(database: database)

        sut.onMove(resultingFen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2")
        XCTAssertEqual(sut.currentOpeningName, "King's Pawn Game")

        sut.onMove(resultingFen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1")

        XCTAssertEqual(sut.currentOpeningName, "Starting Position")
        XCTAssertEqual(sut.currentECO, "")
    }

    func test_onMove_findsTwoDifferentOpeningsSequentially() {
        let fen1 = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -"
        let fen2 = "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq -"
        let database = [
            fen1: ECOOpening(eco: "C20", name: "King's Pawn Game"),
            fen2: ECOOpening(eco: "C44", name: "Scotch Game")
        ]
        let sut = makeSUT(database: database)

        sut.onMove(resultingFen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2")
        XCTAssertEqual(sut.currentOpeningName, "King's Pawn Game")

        sut.onMove(resultingFen: "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 3")
        XCTAssertEqual(sut.currentOpeningName, "Scotch Game")
    }

    func test_onMove_transitionsFromFoundToNotFoundToFound() {
        let fen1 = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -"
        let fen2 = "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq -"
        let database = [
            fen1: ECOOpening(eco: "C20", name: "King's Pawn Game"),
            fen2: ECOOpening(eco: "C44", name: "Scotch Game")
        ]
        let sut = makeSUT(database: database)

        sut.onMove(resultingFen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2")
        XCTAssertEqual(sut.currentOpeningName, "King's Pawn Game")

        sut.onMove(resultingFen: "rnbqkb1r/pppp1ppp/5n2/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 4")
        XCTAssertEqual(sut.currentOpeningName, "King's Pawn Game", "Should retain previous when not found")

        sut.onMove(resultingFen: "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 3")
        XCTAssertEqual(sut.currentOpeningName, "Scotch Game")
    }

    // MARK: - updateDetector Tests

    func test_updateDetector_replacesDetectorForSubsequentMoves() {
        let fen1 = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -"
        let originalDB = [fen1: ECOOpening(eco: "C20", name: "King's Pawn Game")]
        let sut = makeSUT(database: originalDB)

        sut.onMove(resultingFen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2")
        XCTAssertEqual(sut.currentOpeningName, "King's Pawn Game")

        let newFen = "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq -"
        let newDB = [newFen: ECOOpening(eco: "C44", name: "Scotch Game")]
        let newDetector = ECODetector(database: newDB)
        sut.updateDetector(newDetector)

        sut.onMove(resultingFen: "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 3")
        XCTAssertEqual(sut.currentOpeningName, "Scotch Game")
    }

    func test_updateDetector_newDetectorDoesNotFindPreviousOpening() {
        let fen1 = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -"
        let originalDB = [fen1: ECOOpening(eco: "C20", name: "King's Pawn Game")]
        let sut = makeSUT(database: originalDB)

        sut.onMove(resultingFen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2")
        XCTAssertEqual(sut.currentOpeningName, "King's Pawn Game")

        let emptyDetector = ECODetector(database: [:])
        sut.updateDetector(emptyDetector)

        sut.onMove(resultingFen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2")
        XCTAssertEqual(sut.currentOpeningName, "King's Pawn Game", "Should retain previous state when new detector has no match")
    }

    // MARK: - Helpers

    private func makeSUT(database: [String: ECOOpening] = [:], file: StaticString = #filePath, line: UInt = #line) -> OpeningRecognitionViewModel {
        let detector = ECODetector(database: database)
        let sut = OpeningRecognitionViewModel(detector: detector)

        trackForMemoryLeaks(detector, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return sut
    }
}
