//
//  ProgressAdapterTests.swift
//  EssentialChessTests
//

import XCTest
import Combine
import EssentialChess

final class ProgressAdapterTests: XCTestCase {
    
    func test_init_setsDefaultProgress() {
        let (sut, _) = makeSUT()
        
        let expectedProgress = UserProgress(
            hiddenRating: 500.0,
            onboardingComplete: false,
            completedPuzzleIDs: [],
            passedExamIDs: [],
            examFailureTimes: [:]
        )
        XCTAssertEqual(sut.currentProgress, expectedProgress)
    }
    
    func test_load_deliversProgressFromStore() {
        let (sut, store) = makeSUT()
        
        let expectedProgress = UserProgress(hiddenRating: 1200.0, onboardingComplete: true)
        
        let exp = expectation(description: "Wait for load completion")
        sut.load { [weak sut] in
            XCTAssertEqual(sut?.currentProgress, expectedProgress)
            exp.fulfill()
        }
        
        store.completeRetrieval(with: expectedProgress)
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_update_modifiesProgressAndSavesToStore() {
        let (sut, store) = makeSUT()
        
        sut.update { progress in
            progress = UserProgress(hiddenRating: 1500.0, onboardingComplete: true)
        }
        
        let expectedProgress = UserProgress(hiddenRating: 1500.0, onboardingComplete: true)
        XCTAssertEqual(sut.currentProgress, expectedProgress)
        XCTAssertEqual(store.messages, [.insert(expectedProgress)])
    }
    
    func test_publisher_publishesProgressOnUpdate() {
        let (sut, _) = makeSUT()
        
        var receivedProgress = [UserProgress]()
        let cancellable = sut.publisher().sink { receivedProgress.append($0) }
        
        sut.update { progress in
            progress = UserProgress(hiddenRating: 1500.0, onboardingComplete: true)
        }
        
        XCTAssertEqual(receivedProgress.count, 2)
        XCTAssertEqual(receivedProgress[0].hiddenRating, 500.0)
        XCTAssertEqual(receivedProgress[1].hiddenRating, 1500.0)
        
        cancellable.cancel()
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: ProgressAdapter, store: ProgressStoreSpy) {
        let store = ProgressStoreSpy()
        let sut = ProgressAdapter(store: store)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        
        return (sut, store)
    }
    
    private class ProgressStoreSpy: ProgressLoader {
        enum Message: Equatable {
            case retrieve
            case insert(UserProgress)
        }
        
        private(set) var messages = [Message]()
        private var retrievalCompletions = [(ProgressLoader.RetrievalResult) -> Void]()
        private var insertionCompletions = [(ProgressLoader.InsertionResult) -> Void]()
        
        func retrieve(completion: @escaping (ProgressLoader.RetrievalResult) -> Void) {
            messages.append(.retrieve)
            retrievalCompletions.append(completion)
        }
        
        func completeRetrieval(with progress: UserProgress?, at index: Int = 0) {
            retrievalCompletions[index](.success(progress))
        }
        
        func completeRetrieval(with error: Error, at index: Int = 0) {
            retrievalCompletions[index](.failure(error))
        }
        
        func insert(_ progress: UserProgress, completion: @escaping (ProgressLoader.InsertionResult) -> Void) {
            messages.append(.insert(progress))
            insertionCompletions.append(completion)
        }
        
        func completeInsertion(with error: Error, at index: Int = 0) {
            insertionCompletions[index](.failure(error))
        }
        
        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](.success(()))
        }
    }
}
