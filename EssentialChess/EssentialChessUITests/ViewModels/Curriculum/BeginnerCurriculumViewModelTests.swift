//
//  BeginnerCurriculumViewModelTests.swift
//  EssentialChessUITests
//

import XCTest
import Combine
import EssentialChess
@testable import EssentialChessUI

final class BeginnerCurriculumViewModelTests: XCTestCase {

    // MARK: - Init Tests

    func test_init_doesNotLoadData() {
        let (sut, _, _) = makeSUT()

        XCTAssertTrue(sut.sections.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - load() Tests

    func test_load_setsIsLoadingTrue() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()

        sut.load()

        XCTAssertTrue(sut.isLoading)
        XCTAssertNil(sut.errorMessage)

        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()
    }

    func test_load_deliversMappedSectionsOnSuccess() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let curriculum = makeCurriculumWithTwoSections()
        let progress = BeginnerProgress(completedPuzzleIDs: [])

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(progress)
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()

        XCTAssertEqual(sut.sections.count, 2)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func test_load_deliversErrorMessageOnFailure() {
        let (sut, curriculumSubject, _) = makeSUT()
        let anyError = NSError(domain: "test", code: 0)

        sut.load()
        curriculumSubject.send(completion: .failure(anyError))
        flushMainQueue()

        XCTAssertTrue(sut.sections.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_load_setsIsLoadingFalseAfterSuccess() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()

        sut.load()
        curriculumSubject.send(makeCurriculumWithTwoSections())
        progressSubject.send(BeginnerProgress(completedPuzzleIDs: []))
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)

        flushMainQueue()

        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Section Mapping Tests

    func test_load_mapsSectionTitlesCorrectly() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let curriculum = makeCurriculumWithTwoSections()

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(BeginnerProgress(completedPuzzleIDs: []))
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()

        XCTAssertEqual(sut.sections[0].title, "Section 1")
        XCTAssertEqual(sut.sections[1].title, "Section 2")
    }

    func test_load_mapsEloRangeWithPrefix() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let curriculum = makeCurriculumWithTwoSections()

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(BeginnerProgress(completedPuzzleIDs: []))
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()

        XCTAssertEqual(sut.sections[0].eloRange, "ELO 100-200")
        XCTAssertEqual(sut.sections[1].eloRange, "ELO 200-300")
    }

    func test_load_allSectionsAreUnlocked() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let curriculum = makeCurriculumWithTwoSections()

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(BeginnerProgress(completedPuzzleIDs: []))
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()

        XCTAssertTrue(sut.sections.allSatisfy { $0.isUnlocked })
    }

    func test_load_allSectionsAreBeginnerMode() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let curriculum = makeCurriculumWithTwoSections()

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(BeginnerProgress(completedPuzzleIDs: []))
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()

        XCTAssertTrue(sut.sections.allSatisfy { $0.isBeginnerMode })
    }

    // MARK: - Progress Mapping Tests

    func test_load_mapsSectionProgressWhenAllComplete() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let curriculum = makeCurriculumWithPuzzles(sectionID: "s1", puzzleIDs: ["p1", "p2", "p3", "p4"])
        let progress = BeginnerProgress(completedPuzzleIDs: ["p1", "p2", "p3", "p4"])

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(progress)
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()

        XCTAssertEqual(sut.sections[0].progress, 1.0, accuracy: 0.001)
    }

    func test_load_mapsSectionProgressWhenHalfComplete() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let curriculum = makeCurriculumWithPuzzles(sectionID: "s1", puzzleIDs: ["p1", "p2", "p3", "p4"])
        let progress = BeginnerProgress(completedPuzzleIDs: ["p1", "p2"])

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(progress)
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()

        XCTAssertEqual(sut.sections[0].progress, 0.5, accuracy: 0.001)
    }

    func test_load_mapsSectionProgressWhenNoneComplete() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let curriculum = makeCurriculumWithPuzzles(sectionID: "s1", puzzleIDs: ["p1", "p2", "p3"])

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(BeginnerProgress(completedPuzzleIDs: []))
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()

        XCTAssertEqual(sut.sections[0].progress, 0.0, accuracy: 0.001)
    }

    func test_load_emptySection_hasZeroProgress() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let section = EloSection(
            id: "empty",
            title: "Empty",
            eloRange: "100-200",
            isLockedByDefault: false,
            categories: []
        )
        let curriculum = Curriculum(
            version: "1",
            metadata: CurriculumMetadata(description: "", totalSections: 1, targetPuzzlesPerSubTheme: 0, targetPuzzlesPerExam: nil),
            sections: [section]
        )

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(BeginnerProgress(completedPuzzleIDs: []))
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()

        XCTAssertEqual(sut.sections[0].progress, 0.0, accuracy: 0.001)
    }

    // MARK: - Category Mapping Tests

    func test_load_mapsCategoryProgressFromSubThemes() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let curriculum = makeCurriculumWithSubThemes(
            sectionID: "s1",
            categoryID: "c1",
            subThemePuzzleIDs: [["st1_p1", "st1_p2"], ["st2_p1", "st2_p2"]]
        )
        let progress = BeginnerProgress(completedPuzzleIDs: ["st1_p1", "st1_p2"])

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(progress)
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()

        let category = sut.sections[0].categories[0]
        XCTAssertEqual(category.progress, 0.5, accuracy: 0.001)
    }

    func test_load_mapsCategoryProgressWhenAllSubThemePuzzlesComplete() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let curriculum = makeCurriculumWithSubThemes(
            sectionID: "s1",
            categoryID: "c1",
            subThemePuzzleIDs: [["st1_p1", "st1_p2"], ["st2_p1"]]
        )
        let progress = BeginnerProgress(completedPuzzleIDs: ["st1_p1", "st1_p2", "st2_p1"])

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(progress)
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()

        let category = sut.sections[0].categories[0]
        XCTAssertEqual(category.progress, 1.0, accuracy: 0.001)
    }

    func test_load_mapsSubThemeCompletedPuzzles() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let curriculum = makeCurriculumWithSubThemes(
            sectionID: "s1",
            categoryID: "c1",
            subThemePuzzleIDs: [["st1_p1", "st1_p2", "st1_p3"]]
        )
        let progress = BeginnerProgress(completedPuzzleIDs: ["st1_p1", "st1_p2"])

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(progress)
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()

        let subTheme = sut.sections[0].categories[0].subThemes![0]
        XCTAssertEqual(subTheme.completedPuzzles, 2)
        XCTAssertEqual(subTheme.totalPuzzles, 3)
    }

    // MARK: - Category Properties

    func test_load_categoryHasNilExamState() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let curriculum = makeCurriculumWithSubThemes(
            sectionID: "s1",
            categoryID: "c1",
            subThemePuzzleIDs: [["p1"]]
        )

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(BeginnerProgress(completedPuzzleIDs: []))
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()

        XCTAssertNil(sut.sections[0].categories[0].examState, "Exam state should be nil in beginner mode")
    }

    func test_load_allCategoriesAreBeginnerMode() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let curriculum = makeCurriculumWithSubThemes(
            sectionID: "s1",
            categoryID: "c1",
            subThemePuzzleIDs: [["p1"]]
        )

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(BeginnerProgress(completedPuzzleIDs: []))
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()

        let category = sut.sections[0].categories[0]
        XCTAssertTrue(category.isBeginnerMode)
    }

    func test_load_subThemeIsBeginnerMode() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let curriculum = makeCurriculumWithSubThemes(
            sectionID: "s1",
            categoryID: "c1",
            subThemePuzzleIDs: [["p1"]]
        )

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(BeginnerProgress(completedPuzzleIDs: []))
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()

        let subTheme = sut.sections[0].categories[0].subThemes![0]
        XCTAssertTrue(subTheme.isBeginnerMode)
    }

    func test_load_puzzleUIModelMapsDomainFields() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let puzzle = Puzzle(id: "test-id", fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", moves: ["e4", "e5"], rating: 1200, tags: ["opening", "tactics"])
        let subTheme = SubTheme(id: "st1", title: "Sub 1", totalPuzzles: 1, puzzles: [puzzle])
        let category = Category(id: "c1", title: "Cat", isExamMode: false, description: "desc", totalPuzzles: 1, puzzles: nil, subThemes: [subTheme])
        let section = EloSection(id: "s1", title: "Sec", eloRange: "100-200", isLockedByDefault: false, categories: [category])
        let curriculum = Curriculum(
            version: "1",
            metadata: CurriculumMetadata(description: "", totalSections: 1, targetPuzzlesPerSubTheme: 0, targetPuzzlesPerExam: nil),
            sections: [section]
        )

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(BeginnerProgress(completedPuzzleIDs: []))
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()

        let puzzleUI = sut.sections[0].categories[0].subThemes![0].puzzles[0]
        XCTAssertEqual(puzzleUI.id, "test-id")
        XCTAssertEqual(puzzleUI.fen, "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
        XCTAssertEqual(puzzleUI.moves, ["e4", "e5"])
        XCTAssertEqual(puzzleUI.rating, 1200)
        XCTAssertEqual(puzzleUI.tags, ["opening", "tactics"])
    }

    func test_load_categoryWithoutSubThemes_hasNilSubThemes() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let puzzle = Puzzle(id: "p1", fen: "", moves: [], rating: 500, tags: [])
        let category = Category(id: "c1", title: "Cat", isExamMode: false, description: nil, totalPuzzles: 1, puzzles: [puzzle], subThemes: nil)
        let section = EloSection(id: "s1", title: "Sec", eloRange: "100-200", isLockedByDefault: false, categories: [category])
        let curriculum = Curriculum(
            version: "1",
            metadata: CurriculumMetadata(description: "", totalSections: 1, targetPuzzlesPerSubTheme: 0, targetPuzzlesPerExam: nil),
            sections: [section]
        )

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(BeginnerProgress(completedPuzzleIDs: []))
        curriculumSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()

        XCTAssertNil(sut.sections[0].categories[0].subThemes)
    }

    // MARK: - Progress Publisher Update Tests

    func test_load_progressUpdate_updatesSectionProgress() {
        let (sut, curriculumSubject, progressSubject) = makeSUT()
        let curriculum = makeCurriculumWithPuzzles(sectionID: "s1", puzzleIDs: ["p1", "p2", "p3", "p4"])

        sut.load()
        curriculumSubject.send(curriculum)
        progressSubject.send(BeginnerProgress(completedPuzzleIDs: []))
        flushMainQueue()

        XCTAssertEqual(sut.sections[0].progress, 0.0, accuracy: 0.001)

        progressSubject.send(BeginnerProgress(completedPuzzleIDs: ["p1", "p2", "p3", "p4"]))
        flushMainQueue()

        XCTAssertEqual(sut.sections[0].progress, 1.0, accuracy: 0.001)
    }

    // MARK: - Helpers

    private func flushMainQueue() {
        let exp = expectation(description: "Wait for main queue")
        DispatchQueue.main.async { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)
    }

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: BeginnerCurriculumViewModel,
        curriculumSubject: PassthroughSubject<Curriculum, Error>,
        progressSubject: PassthroughSubject<BeginnerProgress, Never>
    ) {
        let curriculumSubject = PassthroughSubject<Curriculum, Error>()
        let progressSubject = PassthroughSubject<BeginnerProgress, Never>()

        let sut = BeginnerCurriculumViewModel(
            curriculumPublisher: { curriculumSubject.eraseToAnyPublisher() },
            progressPublisher: { progressSubject.eraseToAnyPublisher() }
        )

        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, curriculumSubject, progressSubject)
    }

    private func makeCurriculumWithTwoSections() -> Curriculum {
        let section1 = EloSection(
            id: "s1", title: "Section 1", eloRange: "100-200",
            isLockedByDefault: false, categories: []
        )
        let section2 = EloSection(
            id: "s2", title: "Section 2", eloRange: "200-300",
            isLockedByDefault: false, categories: []
        )
        return Curriculum(
            version: "1",
            metadata: CurriculumMetadata(description: "", totalSections: 2, targetPuzzlesPerSubTheme: 0, targetPuzzlesPerExam: nil),
            sections: [section1, section2]
        )
    }

    private func makeCurriculumWithPuzzles(sectionID: String, puzzleIDs: [String]) -> Curriculum {
        let puzzles = puzzleIDs.map { Puzzle(id: $0, fen: "", moves: [], rating: 500, tags: []) }
        let subTheme = SubTheme(id: "st1", title: "Sub 1", totalPuzzles: puzzles.count, puzzles: puzzles)
        let category = Category(id: "c1", title: "Cat", isExamMode: false, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: [subTheme])
        let section = EloSection(id: sectionID, title: "Section", eloRange: "100-200", isLockedByDefault: false, categories: [category])
        return Curriculum(
            version: "1",
            metadata: CurriculumMetadata(description: "", totalSections: 1, targetPuzzlesPerSubTheme: 0, targetPuzzlesPerExam: nil),
            sections: [section]
        )
    }

    private func makeCurriculumWithSubThemes(sectionID: String, categoryID: String, subThemePuzzleIDs: [[String]]) -> Curriculum {
        let subThemes = subThemePuzzleIDs.map { ids in
            let puzzles = ids.map { Puzzle(id: $0, fen: "", moves: [], rating: 500, tags: []) }
            return SubTheme(id: "st_\(ids[0])", title: "Sub", totalPuzzles: puzzles.count, puzzles: puzzles)
        }
        let category = Category(id: categoryID, title: "Cat", isExamMode: false, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: subThemes)
        let section = EloSection(id: sectionID, title: "Section", eloRange: "100-200", isLockedByDefault: false, categories: [category])
        return Curriculum(
            version: "1",
            metadata: CurriculumMetadata(description: "", totalSections: 1, targetPuzzlesPerSubTheme: 0, targetPuzzlesPerExam: nil),
            sections: [section]
        )
    }
}
