//
//  UbiquitousProgressStoreTests.swift
//  EssentialChess
//

import XCTest
import EssentialChess

final class UbiquitousProgressStoreTests: XCTestCase {
    
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
        let (sut, stores) = makeSUT()
        stores.cloud.store["user_progress_cache"] = Data("invalid json".utf8)
        
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
    
    func test_insert_deliversSuccessOnValidInsertionAndSynchronizes() {
        let (sut, stores) = makeSUT()
        let progress = makeProgress()
        
        let expectation = expectation(description: "Wait for store insertion")
        sut.insert(progress) { result in
            if case let .failure(error) = result {
                XCTFail("Expected successful insertion, got \(error) instead")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertNotNil(stores.cloud.store["user_progress_cache"])
        XCTAssertEqual(stores.cloud.syncCallCount, 1, "Expected synchronize to be called on insertion")
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
    
    func test_retrieve_migratesDataFromLocalStoreWhenCloudIsEmpty() {
        let cloudStore = MockKeyValueStore()
        let localStore = MockKeyValueStore()
        let sut = UbiquitousProgressStore(store: cloudStore, localStore: localStore)
        
        let progress = makeProgress()
        // Simulate data existing only in localStore
        let oldStore = UserDefaultsProgressStore(store: localStore)
        let oldInsertionExpectation = expectation(description: "Wait for old store insertion")
        oldStore.insert(progress) { _ in
            oldInsertionExpectation.fulfill()
        }
        wait(for: [oldInsertionExpectation], timeout: 1.0)
        
        // Cloud is empty, should trigger migration
        let retrievalExpectation = expectation(description: "Wait for store retrieval and migration")
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
        
        XCTAssertEqual(cloudStore.syncCallCount, 1, "Expected synchronize to be called during migration")
        XCTAssertNotNil(cloudStore.store["user_progress_cache"], "Expected data to be migrated to cloud")
        XCTAssertTrue(localStore.removedKeys.contains("user_progress_cache"), "Expected local store data to be removed after migration")
    }
    
    func test_retrieve_deliversEmptyWhenLocalStoreDataIsInvalidDuringMigration() {
        let cloudStore = MockKeyValueStore()
        let localStore = MockKeyValueStore()
        let sut = UbiquitousProgressStore(store: cloudStore, localStore: localStore)
        
        // Simulate invalid data in localStore
        localStore.store["user_progress_cache"] = Data("invalid json".utf8)
        
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
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: ProgressStore, stores: (cloud: MockKeyValueStore, local: MockKeyValueStore)) {
        let cloudStore = MockKeyValueStore()
        let localStore = MockKeyValueStore()
        let sut = UbiquitousProgressStore(store: cloudStore, localStore: localStore)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, (cloudStore, localStore))
    }
    
    private func makeProgress() -> UserProgress {
        return UserProgress(
            hiddenRating: 1200.0,
            actualRating: 1215.0,
            onboardingComplete: true,
            completedPuzzleIDs: ["p1", "p2"],
            passedExamIDs: ["e1"],
            examFailureTimes: ["e2": Date()],
            isPro: true,
            dailyPuzzleMixCount: 5,
            lastPuzzleMixDate: Date(),
            dailyPuzzleStormCount: 1,
            lastPuzzleStormDate: Date()
        )
    }
}
