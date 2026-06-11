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
        let (_, curriculumSubject, mixPoolSubject) = makeSUT()
        
        XCTAssertFalse(curriculumSubject.hasSubscribers)
        XCTAssertFalse(mixPoolSubject.hasSubscribers)
    }
    
    func test_load_requestsDataFromPublishers() {
        let (sut, curriculumSubject, mixPoolSubject) = makeSUT()
        
        sut.load()
        
        XCTAssertTrue(curriculumSubject.hasSubscribers)
        XCTAssertTrue(mixPoolSubject.hasSubscribers)
        XCTAssertTrue(sut.isLoading, "Expected loading state to be true when fetching starts")
    }
    
    func test_load_deliversDataOnSuccess() {
        let (sut, curriculumSubject, mixPoolSubject) = makeSUT()
        let expectedCurriculum = Curriculum(version: "1", metadata: CurriculumMetadata(description: "", totalSections: 0, targetPuzzlesPerSubTheme: 0, targetPuzzlesPerExam: nil), sections: [])
        let expectedMixPool = MixPool(id: "1", metadata: MixPoolMetadata(totalPuzzles: 0, supportedModes: []), difficultyTiers: [])
        
        sut.load()
        
        curriculumSubject.send(expectedCurriculum)
        mixPoolSubject.send(expectedMixPool)
        
        curriculumSubject.send(completion: .finished)
        mixPoolSubject.send(completion: .finished)
        
        XCTAssertEqual(sut.sections, expectedCurriculum.sections)
        XCTAssertFalse(sut.isLoading, "Expected loading state to be false after completion")
        XCTAssertNil(sut.errorMessage)
    }
    
    func test_load_deliversErrorMessageOnFailure() {
        let (sut, curriculumSubject, mixPoolSubject) = makeSUT()
        let anyError = NSError(domain: "any", code: 0)
        
        sut.load()
        
        curriculumSubject.send(completion: .failure(anyError))
        mixPoolSubject.send(completion: .failure(anyError))
        
        XCTAssertTrue(sut.sections.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage, "Expected error message on failure")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (
        sut: CurriculumViewModel,
        curriculumSubject: PublisherSpy<Curriculum>,
        mixPoolSubject: PublisherSpy<MixPool>
    ) {
        let curriculumSpy = PublisherSpy<Curriculum>()
        let mixPoolSpy = PublisherSpy<MixPool>()
        
        let sut = CurriculumViewModel(
            curriculumPublisher: { curriculumSpy.publisher },
            mixPoolPublisher: { mixPoolSpy.publisher }
        )
        
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, curriculumSpy, mixPoolSpy)
    }
    
    private class PublisherSpy<T> {
        let subject = PassthroughSubject<T, Error>()
        var hasSubscribers = false
        
        var publisher: AnyPublisher<T, Error> {
            subject
                .handleEvents(receiveSubscription: { [weak self] _ in self?.hasSubscribers = true })
                .eraseToAnyPublisher()
        }
        
        func send(_ value: T) {
            subject.send(value)
        }
        
        func send(completion: Subscribers.Completion<Error>) {
            subject.send(completion: completion)
        }
    }
}
