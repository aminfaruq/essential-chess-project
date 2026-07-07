//
//  CurriculumViewModelTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 11/06/26.
//

import XCTest
import Combine
import EssentialChess
@testable import EssentialChessUI

final class CurriculumViewModelTests: XCTestCase {

    // MARK: - Init Tests

    func test_init_doesNotRequestData() {
        let (sut, _, _, _) = makeSUT()

        XCTAssertTrue(sut.sections.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - load() Success Tests

    func test_load_deliversMappedDataOnSuccess() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()

        let expectedCurriculum = makeCurriculum()
        let expectedMixPool = makeMixPool()
        let expectedProgress = makeUserProgress(passedExamIDs: [])

        sut.load()

        curriculumSubject.send(expectedCurriculum)
        mixPoolSubject.send(expectedMixPool)
        progressSubject.send(expectedProgress)
        curriculumSubject.send(completion: .finished)
        mixPoolSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)

        flushMainQueue()

        XCTAssertEqual(sut.sections.count, expectedCurriculum.sections.count)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func test_load_setsIsLoadingTrueWhileLoading() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()

        sut.load()

        XCTAssertTrue(sut.isLoading)

        curriculumSubject.send(makeCurriculum())
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(makeUserProgress())
        curriculumSubject.send(completion: .finished)
        mixPoolSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        flushMainQueue()
    }

    // MARK: - load() Failure Tests

    func test_load_deliversErrorMessageOnCurriculumFailure() {
        let (sut, curriculumSubject, _, _) = makeSUT()
        let anyError = NSError(domain: "any", code: 0)

        sut.load()
        curriculumSubject.send(completion: .failure(anyError))

        flushMainQueue()

        XCTAssertTrue(sut.sections.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_load_deliversErrorMessageOnMixPoolFailure() {
        let (sut, curriculumSubject, mixPoolSubject, _) = makeSUT()
        let anyError = NSError(domain: "any", code: 0)

        sut.load()
        curriculumSubject.send(makeCurriculum())
        mixPoolSubject.send(completion: .failure(anyError))

        flushMainQueue()

        XCTAssertTrue(sut.sections.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Section Mapping Tests

    func test_load_mapsSectionTitleAndEloRange() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let section = EloSection(id: "s1", title: "Basics", eloRange: "100-200", isLockedByDefault: false, categories: [])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section])

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(makeUserProgress())
        flushMainQueue()

        XCTAssertEqual(sut.sections[0].title, "Basics")
        XCTAssertEqual(sut.sections[0].eloRange, "ELO 100-200")
    }

    func test_load_sectionProgressIsCappedAt99WhenExamNotPassed() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let puzzle = Puzzle(id: "p1", fen: "", moves: [], rating: 500, tags: [])
        let subTheme = SubTheme(id: "st1", title: "ST", totalPuzzles: 1, puzzles: [puzzle])
        let category = Category(id: "c1", title: "Cat", isExamMode: false, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: [subTheme])
        let section = EloSection(id: "s1", title: "Sec", eloRange: "100-200", isLockedByDefault: false, categories: [category])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section])
        let progress = makeUserProgress(completedPuzzleIDs: ["p1"], passedExamIDs: [])

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(progress)
        flushMainQueue()

        XCTAssertEqual(sut.sections[0].progress, 0.99, accuracy: 0.001)
    }

    func test_load_sectionProgressIs1WhenExamPassed() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let exam = Category(id: "exam_1", title: "Exam", isExamMode: true, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: nil)
        let section = EloSection(id: "s1", title: "Sec", eloRange: "100-200", isLockedByDefault: false, categories: [exam])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section])
        let progress = makeUserProgress(passedExamIDs: ["exam_1"])

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(progress)
        flushMainQueue()

        XCTAssertEqual(sut.sections[0].progress, 1.0, accuracy: 0.001)
    }

    // MARK: - Section Unlock Tests

    func test_load_firstSectionIsAlwaysUnlocked() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let section = EloSection(id: "s1", title: "First", eloRange: "1000-1100", isLockedByDefault: true, categories: [])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section])
        let progress = makeUserProgress(hiddenRating: 500)

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(progress)
        flushMainQueue()

        XCTAssertTrue(sut.sections[0].isUnlocked)
    }

    func test_load_sectionUnlockedWhenRatingExceedsFloor() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let section1 = EloSection(id: "s1", title: "S1", eloRange: "100-200", isLockedByDefault: false, categories: [])
        let section2 = EloSection(id: "s2", title: "S2", eloRange: "1000-1200", isLockedByDefault: true, categories: [])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section1, section2])
        let progress = makeUserProgress(hiddenRating: 1100)

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(progress)
        flushMainQueue()

        XCTAssertTrue(sut.sections[1].isUnlocked)
    }

    func test_load_sectionUnlockedWhenPreviousExamPassed() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let exam1 = Category(id: "exam_1", title: "Exam 1", isExamMode: true, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: nil)
        let section1 = EloSection(id: "s1", title: "S1", eloRange: "100-200", isLockedByDefault: false, categories: [exam1])
        let section2 = EloSection(id: "s2", title: "S2", eloRange: "200-300", isLockedByDefault: true, categories: [])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section1, section2])
        let progress = makeUserProgress(hiddenRating: 150, passedExamIDs: ["exam_1"])

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(progress)
        flushMainQueue()

        XCTAssertTrue(sut.sections[1].isUnlocked)
    }

    func test_load_sectionLockedWhenPreviousExamNotPassed() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let exam1 = Category(id: "exam_1", title: "Exam 1", isExamMode: true, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: nil)
        let section1 = EloSection(id: "s1", title: "S1", eloRange: "100-200", isLockedByDefault: false, categories: [exam1])
        let section2 = EloSection(id: "s2", title: "S2", eloRange: "200-300", isLockedByDefault: true, categories: [])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section1, section2])
        let progress = makeUserProgress(hiddenRating: 150, passedExamIDs: [])

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(progress)
        flushMainQueue()

        XCTAssertFalse(sut.sections[1].isUnlocked)
    }

    func test_load_sectionUnlockedWhenPreviousSectionHasNoExam() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let section1 = EloSection(id: "s1", title: "S1", eloRange: "100-200", isLockedByDefault: false, categories: [])
        let section2 = EloSection(id: "s2", title: "S2", eloRange: "200-300", isLockedByDefault: true, categories: [])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section1, section2])
        let progress = makeUserProgress(hiddenRating: 150, passedExamIDs: [])

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(progress)
        flushMainQueue()

        XCTAssertTrue(sut.sections[1].isUnlocked)
    }

    // MARK: - Sequential Progression Tests

    func test_load_mapsSequentialProgressionCorrectly() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let dummyCurriculum = makeSequentialCurriculum()
        let dummyMixPool = makeMixPool()

        sut.load()
        curriculumSubject.send(dummyCurriculum)
        mixPoolSubject.send(dummyMixPool)

        let initialProgress = makeUserProgress(hiddenRating: 150.0, passedExamIDs: [])
        progressSubject.send(initialProgress)
        flushMainQueue()

        XCTAssertTrue(sut.sections[0].isUnlocked)
        XCTAssertFalse(sut.sections[1].isUnlocked)

        let advancedProgress = makeUserProgress(hiddenRating: 150.0, passedExamIDs: ["exam_1"])
        progressSubject.send(advancedProgress)
        flushMainQueue()

        XCTAssertTrue(sut.sections[1].isUnlocked)
    }

    // MARK: - Exam State Tests

    func test_load_nonExamCategory_hasNilExamState() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let category = Category(id: "c1", title: "Cat", isExamMode: false, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: nil)
        let section = EloSection(id: "s1", title: "Sec", eloRange: "100-200", isLockedByDefault: false, categories: [category])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section])

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(makeUserProgress())
        flushMainQueue()

        XCTAssertNil(sut.sections[0].categories[0].examState)
    }

    func test_load_passedExam_showsPassedState() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let exam = Category(id: "exam_1", title: "Exam", isExamMode: true, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: nil)
        let section = EloSection(id: "s1", title: "Sec", eloRange: "100-200", isLockedByDefault: false, categories: [exam])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section])
        let progress = makeUserProgress(passedExamIDs: ["exam_1"])

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(progress)
        flushMainQueue()

        XCTAssertEqual(sut.sections[0].categories[0].examState, .passed(message: "Passed — section unlocked!"))
    }

    func test_load_lockedSectionExam_showsLockedState() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let exam1 = Category(id: "exam_1", title: "Exam", isExamMode: true, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: nil)
        let section1 = EloSection(id: "s1", title: "S1", eloRange: "100-200", isLockedByDefault: false, categories: [exam1])
        let exam2 = Category(id: "exam_2", title: "Exam 2", isExamMode: true, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: nil)
        let section2 = EloSection(id: "s2", title: "S2", eloRange: "200-300", isLockedByDefault: true, categories: [exam2])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section1, section2])
        let progress = makeUserProgress(hiddenRating: 150, passedExamIDs: [])

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(progress)
        flushMainQueue()

        XCTAssertEqual(sut.sections[1].categories[0].examState, .locked(reason: "Complete previous section to unlock"))
    }

    func test_load_incompleteSectionExam_showsLockedState() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let puzzle = Puzzle(id: "p1", fen: "", moves: [], rating: 500, tags: [])
        let subTheme = SubTheme(id: "st1", title: "ST", totalPuzzles: 2, puzzles: [puzzle, Puzzle(id: "p2", fen: "", moves: [], rating: 500, tags: [])])
        let category = Category(id: "c1", title: "Cat", isExamMode: false, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: [subTheme])
        let exam = Category(id: "exam_1", title: "Exam", isExamMode: true, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: nil)
        let section = EloSection(id: "s1", title: "Sec", eloRange: "100-200", isLockedByDefault: false, categories: [category, exam])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section])
        let progress = makeUserProgress(completedPuzzleIDs: ["p1"], passedExamIDs: [])

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(progress)
        flushMainQueue()

        XCTAssertEqual(sut.sections[0].categories[1].examState, .locked(reason: "Complete all themes to unlock"))
    }

    func test_load_examOnCooldown_showsCooldownState() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let puzzle = Puzzle(id: "p1", fen: "", moves: [], rating: 500, tags: [])
        let subTheme = SubTheme(id: "st1", title: "ST", totalPuzzles: 1, puzzles: [puzzle])
        let category = Category(id: "c1", title: "Cat", isExamMode: false, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: [subTheme])
        let exam = Category(id: "exam_1", title: "Exam", isExamMode: true, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: nil)
        let section = EloSection(id: "s1", title: "Sec", eloRange: "100-200", isLockedByDefault: false, categories: [category, exam])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section])
        let recentFail = Date().addingTimeInterval(-1800)
        let progress = UserProgress(
            hiddenRating: 1500, onboardingComplete: true, completedPuzzleIDs: ["p1"],
            passedExamIDs: [], examFailureTimes: ["exam_1": recentFail], unlockedFeatures: []
        )

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(progress)
        flushMainQueue()

        XCTAssertEqual(sut.sections[0].categories[1].examState, .onCooldown(availableIn: "On Cooldown"))
    }

    func test_load_unlockedExam_showsUnlockedState() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let puzzle = Puzzle(id: "p1", fen: "", moves: [], rating: 500, tags: [])
        let subTheme = SubTheme(id: "st1", title: "ST", totalPuzzles: 1, puzzles: [puzzle])
        let category = Category(id: "c1", title: "Cat", isExamMode: false, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: [subTheme])
        let exam = Category(id: "exam_1", title: "Exam", isExamMode: true, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: nil)
        let section = EloSection(id: "s1", title: "Sec", eloRange: "100-200", isLockedByDefault: false, categories: [category, exam])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section])
        let progress = makeUserProgress(completedPuzzleIDs: ["p1"], passedExamIDs: [])

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(progress)
        flushMainQueue()

        XCTAssertEqual(sut.sections[0].categories[1].examState, .unlocked(livesText: "3 lives · 10 random puzzles"))
    }

    // MARK: - Category & SubTheme Mapping Tests

    func test_load_mapsCategoryFields() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let category = Category(id: "c1", title: "Checkmates", isExamMode: false, description: "Learn checkmates", totalPuzzles: 50, puzzles: nil, subThemes: nil)
        let section = EloSection(id: "s1", title: "Sec", eloRange: "100-200", isLockedByDefault: false, categories: [category])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section])

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(makeUserProgress())
        flushMainQueue()

        let cat = sut.sections[0].categories[0]
        XCTAssertEqual(cat.id, "c1")
        XCTAssertEqual(cat.title, "Checkmates")
        XCTAssertEqual(cat.description, "Learn checkmates")
        XCTAssertEqual(cat.totalPuzzles, 50)
        XCTAssertEqual(cat.isBeginnerMode, false)
    }

    func test_load_mapsSubThemeCompletedPuzzles() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let puzzles = [
            Puzzle(id: "p1", fen: "", moves: [], rating: 500, tags: []),
            Puzzle(id: "p2", fen: "", moves: [], rating: 500, tags: []),
            Puzzle(id: "p3", fen: "", moves: [], rating: 500, tags: [])
        ]
        let subTheme = SubTheme(id: "st1", title: "Pins", totalPuzzles: 3, puzzles: puzzles)
        let category = Category(id: "c1", title: "Cat", isExamMode: false, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: [subTheme])
        let section = EloSection(id: "s1", title: "Sec", eloRange: "100-200", isLockedByDefault: false, categories: [category])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section])
        let progress = makeUserProgress(completedPuzzleIDs: ["p1", "p3"])

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(progress)
        flushMainQueue()

        let st = sut.sections[0].categories[0].subThemes![0]
        XCTAssertEqual(st.completedPuzzles, 2)
        XCTAssertEqual(st.totalPuzzles, 3)
        XCTAssertEqual(st.isBeginnerMode, false)
    }

    func test_load_puzzleUIModelMapsCorrectly() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let puzzle = Puzzle(id: "p1", fen: "fen-data", moves: ["e4", "e5"], rating: 900, tags: ["tactic"])
        let subTheme = SubTheme(id: "st1", title: "ST", totalPuzzles: 1, puzzles: [puzzle])
        let category = Category(id: "c1", title: "Cat", isExamMode: false, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: [subTheme])
        let section = EloSection(id: "s1", title: "Sec", eloRange: "100-200", isLockedByDefault: false, categories: [category])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section])

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(makeUserProgress())
        flushMainQueue()

        let pui = sut.sections[0].categories[0].subThemes![0].puzzles[0]
        XCTAssertEqual(pui.id, "p1")
        XCTAssertEqual(pui.fen, "fen-data")
        XCTAssertEqual(pui.moves, ["e4", "e5"])
        XCTAssertEqual(pui.rating, 900)
        XCTAssertEqual(pui.tags, ["tactic"])
    }

    // MARK: - Progress Publisher Update Tests

    func test_load_progressUpdate_updatesSections() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let exam = Category(id: "exam_1", title: "Exam", isExamMode: true, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: nil)
        let section = EloSection(id: "s1", title: "Sec", eloRange: "100-200", isLockedByDefault: false, categories: [exam])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section])

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(makeUserProgress(passedExamIDs: []))
        flushMainQueue()

        XCTAssertEqual(sut.sections[0].categories[0].examState, .locked(reason: "Complete all themes to unlock"))

        progressSubject.send(makeUserProgress(passedExamIDs: ["exam_1"]))
        flushMainQueue()

        XCTAssertEqual(sut.sections[0].categories[0].examState, .passed(message: "Passed — section unlocked!"))
    }

    func test_load_progressUpdate_updatesSectionUnlockState() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let exam1 = Category(id: "exam_1", title: "Exam 1", isExamMode: true, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: nil)
        let section1 = EloSection(id: "s1", title: "S1", eloRange: "100-200", isLockedByDefault: false, categories: [exam1])
        let section2 = EloSection(id: "s2", title: "S2", eloRange: "200-300", isLockedByDefault: true, categories: [])
        let curriculum = Curriculum(version: "1", metadata: makeMetadata(), sections: [section1, section2])

        sut.load()
        curriculumSubject.send(curriculum)
        mixPoolSubject.send(makeMixPool())
        progressSubject.send(makeUserProgress(hiddenRating: 150, passedExamIDs: []))
        flushMainQueue()

        XCTAssertFalse(sut.sections[1].isUnlocked)

        progressSubject.send(makeUserProgress(hiddenRating: 150, passedExamIDs: ["exam_1"]))
        flushMainQueue()

        XCTAssertTrue(sut.sections[1].isUnlocked)
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
        sut: CurriculumViewModel,
        curriculumSubject: PassthroughSubject<Curriculum, Error>,
        mixPoolSubject: PassthroughSubject<MixPool, Error>,
        progressSubject: PassthroughSubject<UserProgress, Never>
    ) {
        let curriculumSubject = PassthroughSubject<Curriculum, Error>()
        let mixPoolSubject = PassthroughSubject<MixPool, Error>()
        let progressSubject = PassthroughSubject<UserProgress, Never>()

        let sut = CurriculumViewModel(
            curriculumPublisher: { curriculumSubject.eraseToAnyPublisher() },
            mixPoolPublisher: { mixPoolSubject.eraseToAnyPublisher() },
            progressPublisher: { progressSubject.eraseToAnyPublisher() }
        )

        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, curriculumSubject, mixPoolSubject, progressSubject)
    }

    private func makeMetadata() -> CurriculumMetadata {
        CurriculumMetadata(description: "", totalSections: 1, targetPuzzlesPerSubTheme: 0, targetPuzzlesPerExam: nil)
    }

    private func makeCurriculum() -> Curriculum {
        Curriculum(version: "1", metadata: makeMetadata(), sections: [])
    }

    private func makeMixPool() -> MixPool {
        MixPool(id: "1", metadata: MixPoolMetadata(totalPuzzles: 0, supportedModes: []), difficultyTiers: [])
    }

    private func makeUserProgress(
        hiddenRating: Double = 1500.0,
        completedPuzzleIDs: Set<String> = [],
        passedExamIDs: Set<String> = [],
        examFailureTimes: [String: Date] = [:],
        unlockedFeatures: Set<ProFeature> = []
    ) -> UserProgress {
        UserProgress(
            hiddenRating: hiddenRating,
            onboardingComplete: true,
            completedPuzzleIDs: completedPuzzleIDs,
            passedExamIDs: passedExamIDs,
            examFailureTimes: examFailureTimes,
            unlockedFeatures: unlockedFeatures
        )
    }

    private func makeSequentialCurriculum() -> Curriculum {
        let puzzle = Puzzle(id: "p1", fen: "", moves: [], rating: 1000, tags: [])
        let exam1 = Category(id: "exam_1", title: "Exam 1", isExamMode: true, description: nil, totalPuzzles: 10, puzzles: [puzzle], subThemes: nil)
        let section1 = EloSection(id: "sec_1", title: "Level 1", eloRange: "100-200", isLockedByDefault: false, categories: [exam1])
        let section2 = EloSection(id: "sec_2", title: "Level 2", eloRange: "200-300", isLockedByDefault: true, categories: [])
        return Curriculum(version: "1", metadata: makeMetadata(), sections: [section1, section2])
    }
}
