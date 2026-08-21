//
//  CurriculumRouterTests.swift
//  EssentialChessAppTests
//
//  Created by App on 21/08/26.
//

import XCTest
import EssentialChessUI
@testable import EssentialChessApp

@MainActor
final class CurriculumRouterTests: XCTestCase {

    func test_init_startsEmpty() {
        let (sut, _) = makeSUT()

        XCTAssertTrue(sut.path.isEmpty)
        XCTAssertNil(sut.presentedExamCategory)
    }

    func test_navigateTo_appendsRouteToPath() {
        let (sut, _) = makeSUT()
        let section = makeSection()

        sut.navigate(to: .sectionDetail(section))

        XCTAssertEqual(sut.path.count, 1)
    }

    func test_pop_removesLastRouteFromPath() {
        let (sut, _) = makeSUT()
        let section = makeSection()

        sut.navigate(to: .sectionDetail(section))
        XCTAssertEqual(sut.path.count, 1)

        sut.pop()
        XCTAssertEqual(sut.path.count, 0)
    }

    func test_pop_onEmptyPath_doesNothing() {
        let (sut, _) = makeSUT()

        sut.pop()

        XCTAssertEqual(sut.path.count, 0)
    }

    func test_popToRoot_clearsAllRoutesAndDismissesExam() {
        let (sut, _) = makeSUT()
        let section = makeSection()
        let exam = makeExamCategory()

        sut.navigate(to: .sectionDetail(section))
        sut.navigate(to: .puzzleSession(title: "Tactics", puzzles: []))
        sut.presentExam(exam)

        XCTAssertEqual(sut.path.count, 2)
        XCTAssertNotNil(sut.presentedExamCategory)

        sut.popToRoot()

        XCTAssertEqual(sut.path.count, 0)
        XCTAssertNil(sut.presentedExamCategory)
    }

    func test_presentExam_setsPresentedExamCategory() {
        let (sut, _) = makeSUT()
        let exam = makeExamCategory()

        sut.presentExam(exam)

        XCTAssertEqual(sut.presentedExamCategory, exam)
    }

    func test_dismissExam_clearsPresentedExamCategory() {
        let (sut, _) = makeSUT()
        let exam = makeExamCategory()

        sut.presentExam(exam)
        XCTAssertNotNil(sut.presentedExamCategory)

        sut.dismissExam()
        XCTAssertNil(sut.presentedExamCategory)
    }

    // MARK: - Helpers

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: CurriculumRouter, empty: Void) {
        let sut = CurriculumRouter()
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, ())
    }

    private func makeSection() -> SectionUIModel {
        SectionUIModel(
            id: "sec_1",
            title: "Fundamentals",
            eloRange: "500-800",
            progress: 0.5,
            isUnlocked: true,
            categories: []
        )
    }

    private func makeExamCategory() -> CategoryUIModel {
        CategoryUIModel(
            id: "exam_1",
            title: "Exam 1",
            progress: 0.0,
            isExamMode: true,
            description: nil,
            totalPuzzles: 10,
            puzzles: [],
            subThemes: nil,
            examState: .unlocked(livesText: "3 lives")
        )
    }
}
