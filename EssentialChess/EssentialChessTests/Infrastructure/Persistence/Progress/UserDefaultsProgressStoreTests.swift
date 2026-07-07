//
//  UserDefaultsProgressStoreTests.swift
//  EssentialChess
//

import XCTest
import EssentialChess

final class UserDefaultsProgressStoreTests: XCTestCase {
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let (sut, _) = makeSUT()
        
        let expectation = expectation(description: "Wait for store retrieval")
        sut.retrieve { result in
            switch result {
            case let .success(progress):
                XCTAssertNil(progress, "Expected empty cache to return nil")
            default:
                XCTFail("Expected successful empty retrieval, got \(result) instead")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_retrieve_deliversFailureOnInvalidCacheData() {
        let (sut, store) = makeSUT()
        store.store["user_progress_cache"] = Data("invalid json".utf8)
        
        let expectation = expectation(description: "Wait for store retrieval")
        sut.retrieve { result in
            switch result {
            case .failure:
                break // Expected decoding failure
            default:
                XCTFail("Expected decoding failure, got \(result) instead")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_insert_deliversSuccessOnValidInsertion() {
        let (sut, store) = makeSUT()
        let progress = makeProgress()
        
        let expectation = expectation(description: "Wait for store insertion")
        sut.insert(progress) { result in
            if case let .failure(error) = result {
                XCTFail("Expected successful insertion, got \(error) instead")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertNotNil(store.store["user_progress_cache"])
    }
    
    func test_retrieve_deliversFoundValuesOnValidCache() {
        let (sut, _) = makeSUT()
        let progress = makeProgress()
        
        let insertionExpectation = expectation(description: "Wait for store insertion")
        sut.insert(progress) { _ in
            insertionExpectation.fulfill()
        }
        wait(for: [insertionExpectation], timeout: 1.0)
        
        let retrievalExpectation = expectation(description: "Wait for store retrieval")
        sut.retrieve { result in
            switch result {
            case let .success(retrievedProgress):
                XCTAssertEqual(retrievedProgress, progress)
            default:
                XCTFail("Expected successful retrieval, got \(result) instead")
            }
            retrievalExpectation.fulfill()
        }
        wait(for: [retrievalExpectation], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: ProgressLoader, store: MockKeyValueStore) {
        let store = MockKeyValueStore()
        let sut = UserDefaultsProgressLoader(store: store)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func makeProgress() -> UserProgress {
        return UserProgress(
            hiddenRating: 1200.0,
            actualRating: 1215.0,
            onboardingComplete: true,
            completedPuzzleIDs: ["p1", "p2"],
            passedExamIDs: ["e1"],
            examFailureTimes: ["e2": Date()],
            unlockedFeatures: [.openingStudy],
            dailyPuzzleMixCount: 5,
            lastPuzzleMixDate: Date(),
            dailyPuzzleStormCount: 1,
            lastPuzzleStormDate: Date()
        )
    }
}
