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
    
    func test_init_doesNotRequestData() {
        let (sut, _, _, _) = makeSUT()
        
        XCTAssertTrue(sut.sections.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    func test_load_deliversMappedDataOnSuccess() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        
        let expectedCurriculum = makeCurriculum()
        let expectedMixPool = makeMixPool()
        let expectedProgress = makeUserProgress(passedExamIDs: [])
        
        sut.load()
        
        // 1. Send values to all publishers
        curriculumSubject.send(expectedCurriculum)
        mixPoolSubject.send(expectedMixPool)
        progressSubject.send(expectedProgress)
        
        // 2. Send completion
        curriculumSubject.send(completion: .finished)
        mixPoolSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        
        // 3. Verify the outcome
        XCTAssertEqual(sut.sections.count, expectedCurriculum.sections.count)
        XCTAssertFalse(sut.isLoading, "Expected loading state to be false after completion")
        XCTAssertNil(sut.errorMessage)
    }
    
    func test_load_deliversErrorMessageOnFailure() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        let anyError = NSError(domain: "any", code: 0)
        
        sut.load()
        
        // Simulate a failure in one of the primary data sources
        curriculumSubject.send(completion: .failure(anyError))
        mixPoolSubject.send(completion: .finished)
        progressSubject.send(completion: .finished)
        
        XCTAssertTrue(sut.sections.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage, "Expected error message on failure")
    }
    
    // MARK: - New Core Logic Tests
    
    func test_load_mapsSequentialProgressionCorrectly() {
        let (sut, curriculumSubject, mixPoolSubject, progressSubject) = makeSUT()
        
        // Create a mock curriculum with 2 sequential levels
        let dummyCurriculum = makeSequentialCurriculum()
        let dummyMixPool = makeMixPool()
        
        sut.load()
        curriculumSubject.send(dummyCurriculum)
        mixPoolSubject.send(dummyMixPool)
        
        // SCENARIO 1: New user (Not yet passed Level 1 exam)
        let initialProgress = makeUserProgress(passedExamIDs: [])
        progressSubject.send(initialProgress)
        
        guard sut.sections.count == 2 else {
            XCTFail("Expected exactly 2 sections to be mapped")
            return
        }
        
        let section1 = sut.sections[0]
        let section2 = sut.sections[1]
        
        XCTAssertTrue(section1.isUnlocked, "Section 1 (Index 0) should ALWAYS be unlocked.")
        XCTAssertFalse(section2.isUnlocked, "Section 2 should be locked because Section 1 Exam is not passed.")
        
        // SCENARIO 2: User passes Level 1 exam
        // The Level 1 exam ID in the makeSequentialCurriculum() function is "exam_1"
        let advancedProgress = makeUserProgress(passedExamIDs: ["exam_1"])
        progressSubject.send(advancedProgress)
        
        let updatedSection2 = sut.sections[1]
        XCTAssertTrue(updatedSection2.isUnlocked, "Section 2 should UNLOCK immediately after passing Section 1 Exam.")
    }
    
    // MARK: - Helpers
    
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
    
    private func makeCurriculum() -> Curriculum {
        return Curriculum(
            version: "1",
            metadata: CurriculumMetadata(description: "", totalSections: 0, targetPuzzlesPerSubTheme: 0, targetPuzzlesPerExam: nil),
            sections: []
        )
    }
    
    private func makeMixPool() -> MixPool {
        return MixPool(
            id: "1",
            metadata: MixPoolMetadata(totalPuzzles: 0, supportedModes: []),
            difficultyTiers: []
        )
    }
    
    private func makeUserProgress(passedExamIDs: Set<String> = []) -> UserProgress {
        return UserProgress(
            hiddenRating: 1500.0,
            onboardingComplete: true,
            completedPuzzleIDs: [],
            passedExamIDs: passedExamIDs,
            examFailureTimes: [:]
        )
    }
    
    // Creates mock data that facilitates sequential unlock testing
    private func makeSequentialCurriculum() -> Curriculum {
        let puzzle = Puzzle(id: "p1", fen: "", moves: [], rating: 1000, tags: [])
        
        // Level 1: Have a test category
        let exam1 = Category(id: "exam_1", title: "Exam 1", isExamMode: true, description: nil, totalPuzzles: 10, puzzles: [puzzle], subThemes: nil)
        let section1 = EloSection(id: "sec_1", title: "Level 1", eloRange: "100-200", isLockedByDefault: false, categories: [exam1])
        
        // Level 2: It doesn't matter what the contents are, the important thing is to test the unlock state.
        let section2 = EloSection(id: "sec_2", title: "Level 2", eloRange: "200-300", isLockedByDefault: true, categories: [])
        
        return Curriculum(
            version: "1",
            metadata: CurriculumMetadata(description: "", totalSections: 2, targetPuzzlesPerSubTheme: 0, targetPuzzlesPerExam: nil),
            sections: [section1, section2]
        )
    }
}
