//
//  BoardGeometryTests.swift
//  ChessBoardTests
//

import XCTest
@testable import ChessBoard

final class BoardGeometryTests: XCTestCase {

    func test_ranks_whenNotFlipped_topToBottomDescending() {
        let sut = BoardGeometry(bounds: CGSize(width: 320, height: 320), isFlipped: false)

        XCTAssertEqual(sut.ranks, [8, 7, 6, 5, 4, 3, 2, 1])
    }

    func test_ranks_whenFlipped_topToBottomAscending() {
        let sut = BoardGeometry(bounds: CGSize(width: 320, height: 320), isFlipped: true)

        XCTAssertEqual(sut.ranks, [1, 2, 3, 4, 5, 6, 7, 8])
    }

    func test_files_whenNotFlipped_leftToRightAtoH() {
        let sut = BoardGeometry(bounds: CGSize(width: 320, height: 320), isFlipped: false)

        XCTAssertEqual(sut.files, ["a", "b", "c", "d", "e", "f", "g", "h"])
    }

    func test_files_whenFlipped_leftToRightHtoA() {
        let sut = BoardGeometry(bounds: CGSize(width: 320, height: 320), isFlipped: true)

        XCTAssertEqual(sut.files, ["h", "g", "f", "e", "d", "c", "b", "a"])
    }

    func test_squareWidth_calculatesCorrectly() {
        let sut = BoardGeometry(bounds: CGSize(width: 400, height: 400), isFlipped: false)

        XCTAssertEqual(sut.squareWidth, 50)
        XCTAssertEqual(sut.squareHeight, 50)
    }

    func test_squareString_returnsNotationForPoint() {
        let sut = BoardGeometry(bounds: CGSize(width: 400, height: 400), isFlipped: false)
        let centerOfA1 = CGPoint(x: 25, y: 375)

        XCTAssertEqual(sut.squareString(at: centerOfA1), "a1")
    }

    func test_squareString_returnsNotationForH8() {
        let sut = BoardGeometry(bounds: CGSize(width: 400, height: 400), isFlipped: false)
        let centerOfH8 = CGPoint(x: 375, y: 25)

        XCTAssertEqual(sut.squareString(at: centerOfH8), "h8")
    }

    func test_squareString_flipped_returnsCorrectNotation() {
        let sut = BoardGeometry(bounds: CGSize(width: 400, height: 400), isFlipped: true)
        let centerOfA8 = CGPoint(x: 375, y: 375)

        XCTAssertEqual(sut.squareString(at: centerOfA8), "a8")
    }

    func test_squareString_outOfBounds_returnsNil() {
        let sut = makeSUT(bounds: CGSize(width: 400, height: 400), isFlipped: false)

        XCTAssertNil(sut.squareString(at: CGPoint(x: -100, y: 200)))
        XCTAssertNil(sut.squareString(at: CGPoint(x: 500, y: 200)))
        XCTAssertNil(sut.squareString(at: CGPoint(x: 200, y: -100)))
    }

    // MARK: - Helpers

    private func makeSUT(bounds: CGSize, isFlipped: Bool) -> BoardGeometry {
        return BoardGeometry(bounds: bounds, isFlipped: isFlipped)
    }
}
