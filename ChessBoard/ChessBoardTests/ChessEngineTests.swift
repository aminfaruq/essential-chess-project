//
//  ChessEngineTests.swift
//  NativeChessBoard
//
//  Created by Amin faruq on 08/06/26.
//

import XCTest
@testable import ChessBoard

@MainActor
final class ChessEngineTests: XCTestCase {

    private let startingFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

    // MARK: - Init & Position Tests

    func test_init_withValidFEN_setsUpInitialState() {
        let sut = makeSUT(fen: startingFEN)

        XCTAssertEqual(sut.sideToMove, .white)

        let e2Piece = sut.piece(at: "e2")
        XCTAssertNotNil(e2Piece)
        XCTAssertEqual(e2Piece?.kind, .pawn)
        XCTAssertEqual(e2Piece?.color, .white)
    }

    func test_piece_atEmptySquare_returnsNil() {
        let sut = makeSUT(fen: startingFEN)

        XCTAssertNil(sut.piece(at: "e4"))
    }

    func test_currentFEN_changesAfterMove() {
        let sut = makeSUT(fen: startingFEN)
        let initialFEN = sut.currentFEN

        _ = sut.move(from: "e2", to: "e4")

        XCTAssertNotEqual(sut.currentFEN, initialFEN)
    }

    // MARK: - Legal Moves Tests

    func test_legalMoves_returnsCorrectSquares() {
        let sut = makeSUT(fen: startingFEN)
        let moves = sut.legalMoves(for: "e2")

        XCTAssertTrue(moves.contains("e3"))
        XCTAssertTrue(moves.contains("e4"))
        XCTAssertFalse(moves.contains("e5"))
    }

    func test_legalMoveCount_startingPosition_is20() {
        let sut = makeSUT(fen: startingFEN)

        XCTAssertEqual(sut.legalMoveCount(), 20)
    }

    // MARK: - Move Tests

    func test_move_validMove_updatesStateAndReturnsTrue() {
        let sut = makeSUT(fen: startingFEN)

        let success = sut.move(from: "e2", to: "e4", promotion: nil)

        XCTAssertTrue(success)
        XCTAssertNil(sut.piece(at: "e2"))
        XCTAssertNotNil(sut.piece(at: "e4"))
        XCTAssertEqual(sut.sideToMove, .black)
    }

    func test_move_invalidSquare_returnsFalse() {
        let sut = makeSUT(fen: startingFEN)

        let success = sut.move(from: "e2", to: "e5")

        XCTAssertFalse(success)
        XCTAssertNotNil(sut.piece(at: "e2"))
        XCTAssertEqual(sut.sideToMove, .white)
    }

    func test_move_promotion_works() {
        let promotionFEN = "8/4P3/8/8/8/8/8/4K2k w - - 0 1"
        let sut = makeSUT(fen: promotionFEN)

        let success = sut.move(from: "e7", to: "e8", promotion: "q")

        XCTAssertTrue(success)
        let promoted = sut.piece(at: "e8")
        XCTAssertEqual(promoted?.kind, .queen)
        XCTAssertEqual(promoted?.color, .white)
    }

    // MARK: - undo & reset Tests

    func test_undo_atStartingPosition_returnsFalse() {
        let sut = makeSUT(fen: startingFEN)

        XCTAssertFalse(sut.undo())
    }

    func test_undo_afterMove_restoresPosition() {
        let sut = makeSUT(fen: startingFEN)

        _ = sut.move(from: "e2", to: "e4")

        XCTAssertTrue(sut.undo())
        XCTAssertNotNil(sut.piece(at: "e2"))
        XCTAssertNil(sut.piece(at: "e4"))
        XCTAssertEqual(sut.sideToMove, .white)
    }

    func test_resetToStart_afterMoves_restoresInitialState() {
        let sut = makeSUT(fen: startingFEN)

        _ = sut.move(from: "e2", to: "e4")
        _ = sut.move(from: "e7", to: "e5")

        sut.resetToStart()

        XCTAssertEqual(sut.sideToMove, .white)
        XCTAssertNotNil(sut.piece(at: "e2"))
        XCTAssertNil(sut.piece(at: "e4"))
    }

    // MARK: - Force Turn Tests

    func test_forceTurn_toBlack_changesSideToMove() {
        let sut = makeSUT(fen: startingFEN)

        sut.forceTurn(to: .black)

        XCTAssertEqual(sut.sideToMove, .black)
    }

    func test_forceTurn_preservesPosition() {
        let sut = makeSUT(fen: startingFEN)
        let e2Before = sut.piece(at: "e2")

        sut.forceTurn(to: .black)

        XCTAssertEqual(sut.piece(at: "e2")?.kind, e2Before?.kind)
    }

    // MARK: - King In Check Tests

    func test_kingInCheckColor_returnsNilWhenNoCheck() {
        let sut = makeSUT(fen: startingFEN)

        XCTAssertNil(sut.kingInCheckColor)
    }

    func test_kingInCheckColor_detectsCheck() {
        let checkFEN = "rnb1kbnr/pppp1ppp/8/4p3/5PPq/8/PPPPP2P/RNBQKBNR w KQkq - 1 3"
        let sut = makeSUT(fen: checkFEN)

        XCTAssertEqual(sut.kingInCheckColor, .white)
    }

    // MARK: - Game State Tests

    func test_gameState_startingPosition_isInProgress() {
        let sut = makeSUT(fen: startingFEN)

        XCTAssertEqual(sut.gameState, .inProgress)
    }


    // MARK: - En Passant Detection

    func test_isEnPassantCapture_pawnDiagonalToEmptySquare_returnsTrue() {
        let sut = makeSUT(fen: startingFEN)
        _ = sut.move(from: "e2", to: "e4")
        _ = sut.move(from: "a7", to: "a6")
        _ = sut.move(from: "e4", to: "e5")
        _ = sut.move(from: "d7", to: "d5")

        let isEP = sut.isEnPassantCapture(from: "e5", to: "d6")

        XCTAssertTrue(isEP)
    }

    func test_isEnPassantCapture_nonPawn_returnsFalse() {
        let sut = makeSUT(fen: startingFEN)
        _ = sut.move(from: "e2", to: "e4")
        _ = sut.move(from: "e7", to: "e5")
        _ = sut.move(from: "g1", to: "f3")

        let isEP = sut.isEnPassantCapture(from: "f3", to: "e5")

        XCTAssertFalse(isEP)
    }

    // MARK: - Castling Tests

    func test_move_castling_kingsideWhite_movesKingAndRook() {
        let sut = makeSUT(fen: "4k3/8/8/8/8/8/8/4K2R w K - 0 1")

        let success = sut.move(from: "e1", to: "g1")

        XCTAssertTrue(success)
        XCTAssertNil(sut.piece(at: "e1"))
        XCTAssertNil(sut.piece(at: "h1"))
        XCTAssertEqual(sut.piece(at: "g1")?.kind, .king)
        XCTAssertEqual(sut.piece(at: "f1")?.kind, .rook)
        XCTAssertEqual(sut.sideToMove, .black)
    }

    func test_move_castling_queensideWhite_movesKingAndRook() {
        let sut = makeSUT(fen: "4k3/8/8/8/8/8/8/R3K3 w Q - 0 1")

        let success = sut.move(from: "e1", to: "c1")

        XCTAssertTrue(success)
        XCTAssertNil(sut.piece(at: "e1"))
        XCTAssertNil(sut.piece(at: "a1"))
        XCTAssertEqual(sut.piece(at: "c1")?.kind, .king)
        XCTAssertEqual(sut.piece(at: "d1")?.kind, .rook)
        XCTAssertEqual(sut.sideToMove, .black)
    }

    func test_move_castling_kingsideBlack_movesKingAndRook() {
        let sut = makeSUT(fen: "4k2r/8/8/8/8/8/8/4K3 b k - 0 1")

        let success = sut.move(from: "e8", to: "g8")

        XCTAssertTrue(success)
        XCTAssertNil(sut.piece(at: "e8"))
        XCTAssertNil(sut.piece(at: "h8"))
        XCTAssertEqual(sut.piece(at: "g8")?.kind, .king)
        XCTAssertEqual(sut.piece(at: "f8")?.kind, .rook)
        XCTAssertEqual(sut.sideToMove, .white)
    }

    func test_move_castling_queensideBlack_movesKingAndRook() {
        let sut = makeSUT(fen: "r3k3/8/8/8/8/8/8/4K3 b q - 0 1")

        let success = sut.move(from: "e8", to: "c8")

        XCTAssertTrue(success)
        XCTAssertNil(sut.piece(at: "e8"))
        XCTAssertNil(sut.piece(at: "a8"))
        XCTAssertEqual(sut.piece(at: "c8")?.kind, .king)
        XCTAssertEqual(sut.piece(at: "d8")?.kind, .rook)
        XCTAssertEqual(sut.sideToMove, .white)
    }

    func test_move_castling_whenKingAlreadyMoved_returnsFalse() {
        let sut = makeSUT(fen: "4k3/8/8/8/8/8/8/4K2R w - - 0 1")

        let success = sut.move(from: "e1", to: "g1")

        XCTAssertFalse(success)
        XCTAssertNotNil(sut.piece(at: "e1"))
        XCTAssertEqual(sut.sideToMove, .white)
    }

    // MARK: - En Passant Execution Tests

    func test_move_enPassantCapture_removesCapturedPawnAndLandsOnTarget() {
        let sut = makeSUT(fen: startingFEN)
        _ = sut.move(from: "e2", to: "e4")
        _ = sut.move(from: "a7", to: "a6")
        _ = sut.move(from: "e4", to: "e5")
        _ = sut.move(from: "d7", to: "d5")

        let success = sut.move(from: "e5", to: "d6")

        XCTAssertTrue(success)
        XCTAssertEqual(sut.piece(at: "d6")?.kind, .pawn)
        XCTAssertEqual(sut.piece(at: "d6")?.color, .white)
        XCTAssertNil(sut.piece(at: "d5"))
        XCTAssertEqual(sut.sideToMove, .black)
    }

    // MARK: - Promotion Kinds Tests

    func test_move_promotion_toRook_promotesToRook() {
        let sut = makeSUT(fen: "8/4P3/8/8/8/8/8/4K2k w - - 0 1")

        _ = sut.move(from: "e7", to: "e8", promotion: "r")

        XCTAssertEqual(sut.piece(at: "e8")?.kind, .rook)
    }

    func test_move_promotion_toBishop_promotesToBishop() {
        let sut = makeSUT(fen: "8/4P3/8/8/8/8/8/4K2k w - - 0 1")

        _ = sut.move(from: "e7", to: "e8", promotion: "b")

        XCTAssertEqual(sut.piece(at: "e8")?.kind, .bishop)
    }

    func test_move_promotion_toKnight_promotesToKnight() {
        let sut = makeSUT(fen: "8/4P3/8/8/8/8/8/4K2k w - - 0 1")

        _ = sut.move(from: "e7", to: "e8", promotion: "n")

        XCTAssertEqual(sut.piece(at: "e8")?.kind, .knight)
    }

    func test_move_promotion_withUnknownCharacter_promotesToQueen() {
        let sut = makeSUT(fen: "8/4P3/8/8/8/8/8/4K2k w - - 0 1")

        _ = sut.move(from: "e7", to: "e8", promotion: "x")

        XCTAssertEqual(sut.piece(at: "e8")?.kind, .queen)
    }

    // MARK: - Helpers

    private func makeSUT(fen: String, file: StaticString = #filePath, line: UInt = #line) -> ChessEngine {
        let sut = ChessEngine(fen: fen)
        addTeardownBlock { [weak sut] in
            XCTAssertNil(sut, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
        return sut
    }
}
