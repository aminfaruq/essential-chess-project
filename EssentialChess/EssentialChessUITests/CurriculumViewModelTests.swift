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
        let expectedProgress = makeUserProgress()
        
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
    
    private func makeUserProgress() -> UserProgress {
        // Using the exact initializer from the domain model
        return UserProgress(
            hiddenRating: 1500.0,
            onboardingComplete: true,
            completedPuzzleIDs: [],
            passedExamIDs: [],
            examFailureTimes: [:]
        )
    }
}
