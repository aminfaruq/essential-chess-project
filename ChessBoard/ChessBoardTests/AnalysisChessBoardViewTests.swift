//
//  AnalysisChessBoardViewTests.swift
//  ChessBoardTests
//
//  Created by Amin faruq on 20/08/26.
//

import XCTest
@testable import ChessBoard

@MainActor
final class AnalysisChessBoardViewTests: XCTestCase {

    func test_setPosition_whiteOrientation_configuresEngineAndUnlocksBoard() {
        let (sut, _, _, stateCaptures) = makeSUT()

        sut.setPosition(fen: "irrelevant", orientation: .white)

        XCTAssertTrue(sut.engine is ChessGameEngineSpy)
        XCTAssertEqual(sut.userColor, .white)
        XCTAssertFalse(sut.isBoardLocked)
        XCTAssertEqual(stateCaptures.value.count, 1)
        XCTAssertEqual(stateCaptures.value.first?.0, [])
        XCTAssertNil(stateCaptures.value.first?.1)
    }

    func test_setPosition_blackOrientation_setsUserOrientationToBlack() {
        let (sut, _, _, _) = makeSUT()

        sut.setPosition(fen: "irrelevant", orientation: .black)

        XCTAssertEqual(sut.userColor, .black)
    }

    func test_currentFen_returnsEngineFen() {
        let (sut, engine, _, _) = makeSUT()
        engine.stubbedCurrentFEN = "8/8/8/8/8/8/8/8 w - - 0 1"

        sut.setPosition(fen: "irrelevant", orientation: .white)

        XCTAssertEqual(sut.currentFen, "8/8/8/8/8/8/8/8 w - - 0 1")
    }

    func test_undoLastMove_whenEngineAccepts_undoesAndBroadcasts() {
        let (sut, engine, _, stateCaptures) = makeSUT()
        sut.setPosition(fen: "irrelevant", orientation: .white)
        engine.stubbedUndoReturn = true

        sut.undoLastMove()

        XCTAssertTrue(engine.receivedMessages.contains(.undo))
        XCTAssertEqual(stateCaptures.value.count, 2)
    }

    func test_undoLastMove_whenEngineRejects_doesNotBroadcast() {
        let (sut, engine, _, stateCaptures) = makeSUT()
        sut.setPosition(fen: "irrelevant", orientation: .white)
        engine.stubbedUndoReturn = false

        sut.undoLastMove()

        XCTAssertTrue(engine.receivedMessages.contains(.undo))
        XCTAssertEqual(stateCaptures.value.count, 1)
    }

    func test_resetToStart_resetsEngineAndBroadcasts() {
        let (sut, engine, _, stateCaptures) = makeSUT()
        sut.setPosition(fen: "irrelevant", orientation: .white)

        sut.resetToStart()

        XCTAssertTrue(engine.receivedMessages.contains(.resetToStart))
        XCTAssertEqual(stateCaptures.value.count, 2)
    }

    func test_flipBoard_togglesOrientationWithoutBroadcast() {
        let (sut, _, _, stateCaptures) = makeSUT()
        sut.setPosition(fen: "irrelevant", orientation: .white)

        sut.flipBoard()

        XCTAssertEqual(sut.userColor, .black)
        XCTAssertEqual(stateCaptures.value.count, 1)
    }

    func test_jump_jumpsEngineAndReportsFen() {
        let (sut, engine, _, stateCaptures) = makeSUT()
        sut.setPosition(fen: "irrelevant", orientation: .white)
        engine.stubbedCurrentFEN = "8/8/8/8/8/8/8/8 b - - 0 1"
        var movedFens = [String]()
        sut.onUserMoved = { movedFens.append($0) }

        sut.jump(to: "m3")

        XCTAssertTrue(engine.receivedMessages.contains(.jump("m3")))
        XCTAssertEqual(movedFens, ["8/8/8/8/8/8/8/8 b - - 0 1"])
        XCTAssertEqual(stateCaptures.value.count, 2)
    }

    // MARK: - Helpers

    private final class StateCaptures {
        var value: [([PGNAnnotation], String?)] = []
    }

    @discardableResult
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: AnalysisChessBoardView, engine: ChessGameEngineSpy, feedback: BoardFeedbackSpy, stateCaptures: StateCaptures) {
        let engine = ChessGameEngineSpy()
        let feedback = BoardFeedbackSpy()
        let sut = AnalysisChessBoardView(frame: .zero, feedback: feedback, engineFactory: { _ in engine })
        let stateCaptures = StateCaptures()
        sut.onStateChanged = { stateCaptures.value.append(($0, $1)) }
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(engine, file: file, line: line)
        trackForMemoryLeaks(feedback, file: file, line: line)
        return (sut, engine, feedback, stateCaptures)
    }
}