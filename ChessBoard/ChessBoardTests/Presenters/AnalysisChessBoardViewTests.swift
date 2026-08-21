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
        let (sut, _, _, stateCaptures, _, _) = makeSUT()
        
        sut.setPosition(fen: "irrelevant", orientation: .white)
        
        XCTAssertTrue(sut.engine is ChessGameEngineSpy)
        XCTAssertEqual(sut.userColor, .white)
        XCTAssertFalse(sut.isBoardLocked)
        XCTAssertEqual(stateCaptures.value.count, 1)
        XCTAssertEqual(stateCaptures.value.first?.0, [])
        XCTAssertNil(stateCaptures.value.first?.1)
    }
    
    func test_setPosition_blackOrientation_setsUserOrientationToBlack() {
        let (sut, _, _, _, _, _) = makeSUT()
        
        sut.setPosition(fen: "irrelevant", orientation: .black)
        
        XCTAssertEqual(sut.userColor, .black)
    }
    
    func test_currentFen_returnsEngineFen() {
        let (sut, engine, _, _, _, _) = makeSUT()
        engine.stubbedCurrentFEN = "8/8/8/8/8/8/8/8 w - - 0 1"
        
        sut.setPosition(fen: "irrelevant", orientation: .white)
        
        XCTAssertEqual(sut.currentFen, "8/8/8/8/8/8/8/8 w - - 0 1")
    }
    
    func test_undoLastMove_whenEngineAccepts_undoesAndBroadcasts() {
        let (sut, engine, _, stateCaptures, _, _) = makeSUT()
        sut.setPosition(fen: "irrelevant", orientation: .white)
        engine.stubbedUndoReturn = true
        
        sut.undoLastMove()
        
        XCTAssertTrue(engine.receivedMessages.contains(.undo))
        XCTAssertEqual(stateCaptures.value.count, 2)
    }
    
    func test_undoLastMove_whenEngineRejects_doesNotBroadcast() {
        let (sut, engine, _, stateCaptures, _, _) = makeSUT()
        sut.setPosition(fen: "irrelevant", orientation: .white)
        engine.stubbedUndoReturn = false
        
        sut.undoLastMove()
        
        XCTAssertTrue(engine.receivedMessages.contains(.undo))
        XCTAssertEqual(stateCaptures.value.count, 1)
    }
    
    func test_resetToStart_resetsEngineAndBroadcasts() {
        let (sut, engine, _, stateCaptures, _, _) = makeSUT()
        sut.setPosition(fen: "irrelevant", orientation: .white)
        
        sut.resetToStart()
        
        XCTAssertTrue(engine.receivedMessages.contains(.resetToStart))
        XCTAssertEqual(stateCaptures.value.count, 2)
    }
    
    func test_flipBoard_togglesOrientationWithoutBroadcast() {
        let (sut, _, _, stateCaptures, _, _) = makeSUT()
        sut.setPosition(fen: "irrelevant", orientation: .white)
        
        sut.flipBoard()
        
        XCTAssertEqual(sut.userColor, .black)
        XCTAssertEqual(stateCaptures.value.count, 1)
    }
    
    func test_jump_jumpsEngineAndReportsFen() {
        let (sut, engine, _, stateCaptures, _, _) = makeSUT()
        sut.setPosition(fen: "irrelevant", orientation: .white)
        engine.stubbedCurrentFEN = "8/8/8/8/8/8/8/8 b - - 0 1"
        var movedFens = [String]()
        sut.onUserMoved = { movedFens.append($0) }
        
        sut.jump(to: "m3")
        
        XCTAssertTrue(engine.receivedMessages.contains(.jump("m3")))
        XCTAssertEqual(movedFens, ["8/8/8/8/8/8/8/8 b - - 0 1"])
        XCTAssertEqual(stateCaptures.value.count, 2)
    }
    
    // MARK: - Move Handling Tests
    
    func test_processUserMove_validMove_inProgress_playsMoveAndReportsUCI() {
        let (sut, engine, feedback, stateCaptures, movedUCIs, _) = makeSUT()
        engine.stubbedPieces["e2"] = EnginePiece(kind: .pawn, color: .white)
        engine.stubbedLegalMoves["e2"] = ["e4"]
        sut.setPosition(fen: "irrelevant", orientation: .white)
        
        sut.processUserMove(from: "e2", to: "e4", promotionChar: nil)
        
        XCTAssertTrue(engine.receivedMessages.contains(.move("e2", "e4", nil)))
        XCTAssertTrue(feedback.receivedMessages.contains(.playMove))
        XCTAssertEqual(movedUCIs.value, ["e2e4"])
        XCTAssertEqual(stateCaptures.value.count, 2)
    }
    
    func test_processUserMove_capture_inProgress_playsCaptureFeedback() {
        let (sut, engine, feedback, _, _, _) = makeSUT()
        engine.stubbedPieces["e2"] = EnginePiece(kind: .pawn, color: .white)
        engine.stubbedPieces["e5"] = EnginePiece(kind: .pawn, color: .black)
        engine.stubbedLegalMoves["e2"] = ["e5"]
        sut.setPosition(fen: "irrelevant", orientation: .white)
        
        sut.processUserMove(from: "e2", to: "e5", promotionChar: nil)
        
        XCTAssertTrue(engine.receivedMessages.contains(.move("e2", "e5", nil)))
        XCTAssertTrue(feedback.receivedMessages.contains(.moveCapture))
        XCTAssertFalse(feedback.receivedMessages.contains(.playMove))
    }
    
    func test_processUserMove_whenCheckmate_playsVictoryAndReportsState() {
        let (sut, engine, feedback, _, _, gameStateReports) = makeSUT()
        engine.stubbedPieces["e2"] = EnginePiece(kind: .pawn, color: .white)
        engine.stubbedLegalMoves["e2"] = ["e4"]
        engine.stubbedGameState = .checkmate(.white)
        sut.setPosition(fen: "irrelevant", orientation: .white)
        
        sut.processUserMove(from: "e2", to: "e4", promotionChar: nil)
        
        XCTAssertTrue(feedback.receivedMessages.contains(.playVictory))
        XCTAssertEqual(gameStateReports.value, ["checkmate_black"])
    }
    
    func test_processUserMove_whenCheck_playsCheckAndReportsState() {
        let (sut, engine, feedback, _, _, gameStateReports) = makeSUT()
        engine.stubbedPieces["e2"] = EnginePiece(kind: .pawn, color: .white)
        engine.stubbedLegalMoves["e2"] = ["e4"]
        engine.stubbedGameState = .check(.black)
        sut.setPosition(fen: "irrelevant", orientation: .white)
        
        sut.processUserMove(from: "e2", to: "e4", promotionChar: nil)
        
        XCTAssertTrue(feedback.receivedMessages.contains(.playCheck))
        XCTAssertEqual(gameStateReports.value, ["check"])
    }
    
    func test_processUserMove_whenStalemate_playsMoveAndReportsState() {
        let (sut, engine, feedback, _, _, gameStateReports) = makeSUT()
        engine.stubbedPieces["e2"] = EnginePiece(kind: .pawn, color: .white)
        engine.stubbedLegalMoves["e2"] = ["e4"]
        engine.stubbedGameState = .stalemate
        sut.setPosition(fen: "irrelevant", orientation: .white)
        
        sut.processUserMove(from: "e2", to: "e4", promotionChar: nil)
        
        XCTAssertTrue(feedback.receivedMessages.contains(.playMove))
        XCTAssertEqual(gameStateReports.value, ["stalemate"])
    }
    
    func test_processUserMove_castlingMove_commitsMove() {
        let (sut, engine, _, _, movedUCIs, _) = makeSUT()
        engine.stubbedPieces["e1"] = EnginePiece(kind: .king, color: .white)
        engine.stubbedLegalMoves["e1"] = ["g1"]
        sut.setPosition(fen: "irrelevant", orientation: .white)
        
        sut.processUserMove(from: "e1", to: "g1", promotionChar: nil)
        
        XCTAssertTrue(engine.receivedMessages.contains(.move("e1", "g1", nil)))
        XCTAssertEqual(movedUCIs.value, ["e1g1"])
    }
    
    func test_processUserMove_illegalMove_doesNotMoveEngine() {
        let (sut, engine, _, _, movedUCIs, _) = makeSUT()
        engine.stubbedPieces["e2"] = EnginePiece(kind: .pawn, color: .white)
        engine.stubbedLegalMoves["e2"] = []
        sut.setPosition(fen: "irrelevant", orientation: .white)
        
        sut.processUserMove(from: "e2", to: "e5", promotionChar: nil)
        
        XCTAssertFalse(engine.receivedMessages.contains(.move("e2", "e5", nil)))
        XCTAssertEqual(movedUCIs.value, [])
    }
    
    func test_playMove_whenNotInWindow_executesMoveAndCompletes() {
        let (sut, engine, feedback, _, _, _) = makeSUT()
        engine.stubbedPieces["e2"] = EnginePiece(kind: .pawn, color: .white)
        engine.stubbedLegalMoves["e2"] = ["e4"]
        sut.setPosition(fen: "irrelevant", orientation: .white)
        var completionCount = 0
        
        sut.playMove(from: "e2", to: "e4", promotion: nil) { completionCount += 1 }
        
        XCTAssertTrue(engine.receivedMessages.contains(.move("e2", "e4", nil)))
        XCTAssertTrue(feedback.receivedMessages.contains(.playMove))
        XCTAssertEqual(completionCount, 1)
    }
    
    // MARK: - Helpers
    
    private final class StateCaptures {
        var value: [([PGNAnnotation], String?)] = []
    }
    
    private final class MovedUCIs {
        var value: [String] = []
    }
    
    private final class GameStateReports {
        var value: [String] = []
    }
    
    @discardableResult
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: AnalysisChessBoardView, engine: ChessGameEngineSpy, feedback: BoardFeedbackSpy, stateCaptures: StateCaptures, movedUCIs: MovedUCIs, gameStateReports: GameStateReports) {
        let engine = ChessGameEngineSpy()
        let feedback = BoardFeedbackSpy()
        let sut = AnalysisChessBoardView(frame: .zero, feedback: feedback, engineFactory: { _ in engine })
        let stateCaptures = StateCaptures()
        let movedUCIs = MovedUCIs()
        let gameStateReports = GameStateReports()
        sut.onStateChanged = { stateCaptures.value.append(($0, $1)) }
        sut.onUserMoved = { movedUCIs.value.append($0) }
        sut.onGameStateChanged = { gameStateReports.value.append($0) }
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(engine, file: file, line: line)
        trackForMemoryLeaks(feedback, file: file, line: line)
        return (sut, engine, feedback, stateCaptures, movedUCIs, gameStateReports)
    }
}