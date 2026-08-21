//
//  PuzzleRouterTests.swift
//  EssentialChessAppTests
//
//  Created by App on 21/08/26.
//

import XCTest
@testable import EssentialChessApp

@MainActor
final class PuzzleRouterTests: XCTestCase {

    func test_init_startsEmpty() {
        let (sut, _) = makeSUT()

        XCTAssertTrue(sut.path.isEmpty)
    }

    func test_navigateTo_appendsRouteToPath() {
        let (sut, _) = makeSUT()

        sut.navigate(to: .puzzleMix)
        XCTAssertEqual(sut.path.count, 1)

        sut.navigate(to: .puzzleStreak)
        XCTAssertEqual(sut.path.count, 2)

        sut.navigate(to: .puzzleStorm)
        XCTAssertEqual(sut.path.count, 3)
    }

    func test_pop_removesLastRouteFromPath() {
        let (sut, _) = makeSUT()

        sut.navigate(to: .puzzleMix)
        sut.navigate(to: .puzzleStreak)
        XCTAssertEqual(sut.path.count, 2)

        sut.pop()
        XCTAssertEqual(sut.path.count, 1)
    }

    func test_pop_onEmptyPath_doesNothing() {
        let (sut, _) = makeSUT()

        sut.pop()

        XCTAssertEqual(sut.path.count, 0)
    }

    func test_popToRoot_clearsAllRoutes() {
        let (sut, _) = makeSUT()

        sut.navigate(to: .puzzleMix)
        sut.navigate(to: .puzzleStreak)
        sut.navigate(to: .puzzleStorm)
        XCTAssertEqual(sut.path.count, 3)

        sut.popToRoot()

        XCTAssertEqual(sut.path.count, 0)
    }

    // MARK: - Helpers

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: PuzzleRouter, empty: Void) {
        let sut = PuzzleRouter()
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, ())
    }
}
