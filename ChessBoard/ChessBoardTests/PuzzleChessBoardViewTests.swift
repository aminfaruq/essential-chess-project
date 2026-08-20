//
//  PuzzleChessBoardViewTests.swift
//  ChessBoardTests
//
//  Created by Amin faruq on 20/08/26.
//

import XCTest
@testable import ChessBoard

@MainActor
final class PuzzleChessBoardViewTests: XCTestCase {

    private let startingFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

    // MARK: - Start Puzzle Tests

    func test_startPuzzle_whiteToMove_setsUserBlackAndReportsReady() {
        let (sut, engine, _) = makeSUT()
        engine.stubbedSideToMove = .white

        sut.startPuzzle(fen: startingFEN, moves: [])

        XCTAssertEqual(sut.userColor, .black)
        XCTAssertEqual(sut.puzzleMode, .standard)
        XCTAssertTrue(sut.isBoardLocked)
    }

    func test_startPuzzle_blackToMove_setsUserWhiteAndReportsReady() {
        let (sut, engine, _) = makeSUT()
        engine.stubbedSideToMove = .black

        var readyTexts = [String]()
        sut.onPuzzleReady = { readyTexts.append($0) }

        sut.startPuzzle(fen: startingFEN, moves: [])

        XCTAssertEqual(sut.userColor, .white)
        XCTAssertEqual(readyTexts, ["White"])
    }

    func test_startPuzzle_replacesEngineWithFactoryResult() {
        let (sut, engine, _) = makeSUT()
        engine.stubbedSideToMove = .black

        sut.startPuzzle(fen: startingFEN, moves: [])

        XCTAssertTrue(sut.engine is ChessGameEngineSpy)
        XCTAssertEqual(sut.engine?.sideToMove, .black)
    }

    // MARK: - Valid Solution Tests

    func test_processUserMove_validSolution_commitsMoveAndPlaysMove() {
        let (sut, engine, feedback) = makeSUT()
        engine.stubbedPieces["e2"] = EnginePiece(kind: .pawn, color: .white)
        engine.stubbedLegalMoves["e2"] = ["e4"]
        sut.startPuzzle(fen: startingFEN, moves: ["e2e4", "e7e5"])
        sut.isBoardLocked = false

        sut.processUserMove(from: "e2", to: "e4", promotionChar: nil)

        XCTAssertTrue(engine.receivedMessages.contains(.move("e2", "e4", nil)))
        XCTAssertTrue(feedback.receivedMessages.contains(.playMove))
        XCTAssertFalse(feedback.receivedMessages.contains(.moveCapture))
        XCTAssertFalse(sut.isPuzzleCompleted)
    }

    func test_processUserMove_captureSolution_playsCaptureFeedback() {
        let (sut, engine, feedback) = makeSUT()
        engine.stubbedPieces["e2"] = EnginePiece(kind: .pawn, color: .white)
        engine.stubbedPieces["e4"] = EnginePiece(kind: .pawn, color: .black)
        engine.stubbedLegalMoves["e2"] = ["e4"]
        sut.startPuzzle(fen: startingFEN, moves: ["e2e4", "e7e5"])
        sut.isBoardLocked = false

        sut.processUserMove(from: "e2", to: "e4", promotionChar: nil)

        XCTAssertTrue(feedback.receivedMessages.contains(.moveCapture))
        XCTAssertFalse(feedback.receivedMessages.contains(.playMove))
    }

    func test_processUserMove_lastExpectedMove_completesPuzzle() {
        let (sut, engine, feedback) = makeSUT()
        engine.stubbedPieces["e2"] = EnginePiece(kind: .pawn, color: .white)
        engine.stubbedLegalMoves["e2"] = ["e4"]
        sut.startPuzzle(fen: startingFEN, moves: ["e2e4"])
        sut.isBoardLocked = false
        var completedCount = 0
        sut.onPuzzleCompleted = { completedCount += 1 }

        sut.processUserMove(from: "e2", to: "e4", promotionChar: nil)

        XCTAssertTrue(sut.isPuzzleCompleted)
        XCTAssertEqual(completedCount, 1)
        XCTAssertTrue(feedback.receivedMessages.contains(.playVictory))
    }

    func test_processUserMove_checkmateMoveNotInSolution_completesPuzzle() {
        let (sut, engine, feedback) = makeSUT()
        engine.stubbedPieces["e2"] = EnginePiece(kind: .pawn, color: .white)
        engine.stubbedLegalMoves["e2"] = ["e4"]
        engine.stubbedWouldMoveResultInCheckmateReturn = true
        sut.startPuzzle(fen: startingFEN, moves: [])
        sut.isBoardLocked = false
        var completedCount = 0
        sut.onPuzzleCompleted = { completedCount += 1 }

        sut.processUserMove(from: "e2", to: "e4", promotionChar: nil)

        XCTAssertTrue(sut.isPuzzleCompleted)
        XCTAssertEqual(completedCount, 1)
        XCTAssertTrue(feedback.receivedMessages.contains(.playVictory))
    }

    // MARK: - Wrong Solution Tests

    func test_processUserMove_illegalTarget_playsIllegalAndDoesNotMove() {
        let (sut, engine, feedback) = makeSUT()
        engine.stubbedPieces["e2"] = EnginePiece(kind: .pawn, color: .white)
        engine.stubbedLegalMoves["e2"] = []
        sut.startPuzzle(fen: startingFEN, moves: ["e2e4"])
        sut.isBoardLocked = false
        var wrongCount = 0
        sut.onPuzzleWrong = { wrongCount += 1 }

        sut.processUserMove(from: "e2", to: "e5", promotionChar: nil)

        XCTAssertTrue(feedback.receivedMessages.contains(.moveIllegal))
        XCTAssertFalse(engine.receivedMessages.contains(.move("e2", "e5", nil)))
        XCTAssertEqual(wrongCount, 0)
        XCTAssertFalse(sut.isPuzzleCompleted)
    }

    func test_processUserMove_legalButWrongSolution_playsIllegalAndReportsWrong() {
        let (sut, engine, feedback) = makeSUT()
        engine.stubbedPieces["e2"] = EnginePiece(kind: .pawn, color: .white)
        engine.stubbedLegalMoves["e2"] = ["e4"]
        sut.startPuzzle(fen: startingFEN, moves: ["g1f3"])
        sut.isBoardLocked = false
        var wrongCount = 0
        sut.onPuzzleWrong = { wrongCount += 1 }

        sut.processUserMove(from: "e2", to: "e4", promotionChar: nil)

        XCTAssertTrue(feedback.receivedMessages.contains(.moveIllegal))
        XCTAssertEqual(wrongCount, 1)
        XCTAssertFalse(engine.receivedMessages.contains(.move("e2", "e4", nil)))
        XCTAssertFalse(sut.isPuzzleCompleted)
        XCTAssertFalse(sut.isBoardLocked)
    }

    // MARK: - Helpers

    @discardableResult
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: PuzzleChessBoardView, engine: ChessGameEngineSpy, feedback: BoardFeedbackSpy) {
        let engine = ChessGameEngineSpy()
        let feedback = BoardFeedbackSpy()
        let sut = PuzzleChessBoardView(frame: .zero, feedback: feedback, engineFactory: { _ in engine })
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(engine, file: file, line: line)
        trackForMemoryLeaks(feedback, file: file, line: line)
        return (sut, engine, feedback)
    }
}