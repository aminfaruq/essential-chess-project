//
//  UbiquitousProgressStoreTests.swift
//  EssentialChess
//

import XCTest
import EssentialChess

final class UbiquitousProgressStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
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
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let progress = UserProgress(
            hiddenRating: 1200.0,
            actualRating: 1215.0,
            onboardingComplete: true,
            completedPuzzleIDs: ["p1", "p2"],
            passedExamIDs: ["e1"],
            examFailureTimes: ["e2": Date()],
            isPro: true,
            dailyPuzzleMixCount: 5,
            lastPuzzleMixDate: Date()
        )
        
        let insertionExpectation = expectation(description: "Wait for store insertion")
        sut.insert(progress) { result in
            if case let .failure(error) = result {
                XCTFail("Expected successful insertion, got \(error) instead")
            }
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
    
    func test_retrieve_migratesDataFromUserDefaultsWhenUbiquitousStoreIsEmpty() {
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        // Insert dummy data directly into UserDefaults to simulate old app state
        let progress = UserProgress(
            hiddenRating: 1500.0,
            actualRating: 1550.0,
            onboardingComplete: true,
            completedPuzzleIDs: ["migration1"],
            passedExamIDs: [],
            examFailureTimes: [:]
        )
        let oldStore = UserDefaultsProgressStore(store: testDefaults)
        
        let oldInsertionExpectation = expectation(description: "Wait for old store insertion")
        oldStore.insert(progress) { _ in
            oldInsertionExpectation.fulfill()
        }
        wait(for: [oldInsertionExpectation], timeout: 1.0)
        
        // SUT should be empty initially in UbiquitousStore, but it should read from UserDefaults and migrate
        let sut = makeSUT(localStore: testDefaults)
        
        let retrievalExpectation = expectation(description: "Wait for store retrieval and migration")
        sut.retrieve { result in
            switch result {
            case let .success(retrievedProgress):
                XCTAssertEqual(retrievedProgress, progress, "Expected to successfully migrate and retrieve data from UserDefaults")
            default:
                XCTFail("Expected successful retrieval, got \(result) instead")
            }
            retrievalExpectation.fulfill()
        }
        
        wait(for: [retrievalExpectation], timeout: 1.0)
        
        // Ensure the old data is cleared from UserDefaults
        XCTAssertNil(testDefaults.data(forKey: "user_progress_cache"), "Expected UserDefaults data to be cleared after migration")
        
        // Ensure data was moved to UbiquitousStore
        let dataInUbiquitous = NSUbiquitousKeyValueStore.default.data(forKey: "user_progress_cache")
        XCTAssertNotNil(dataInUbiquitous, "Expected data to be written to UbiquitousStore after migration")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(localStore: UserDefaults? = nil, file: StaticString = #filePath, line: UInt = #line) -> ProgressStore {
        let defaults = localStore ?? UserDefaults(suiteName: testSuiteName)!
        let sut = UbiquitousProgressStore(store: .default, localStore: defaults)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private let testSuiteName = "testUbiquitousStore"
    
    private func setupEmptyStoreState() {
        UserDefaults().removePersistentDomain(forName: testSuiteName)
        NSUbiquitousKeyValueStore.default.removeObject(forKey: "user_progress_cache")
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    private func undoStoreSideEffects() {
        UserDefaults().removePersistentDomain(forName: testSuiteName)
        NSUbiquitousKeyValueStore.default.removeObject(forKey: "user_progress_cache")
        NSUbiquitousKeyValueStore.default.synchronize()
    }
}
