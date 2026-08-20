//
//  BeginnerProgressAdapterTests.swift
//  EssentialChessTests
//

import XCTest
import Combine
import EssentialChess

final class BeginnerProgressAdapterTests: XCTestCase {
    
    func test_init_publishesCurrentStoreProgress() {
        let store = BeginnerProgressStoreSpy()
        store.currentProgress = BeginnerProgress(completedPuzzleIDs: ["p1"])
        let sut = BeginnerProgressAdapter(store: store)
        
        trackForMemoryLeaks(sut, file: #filePath, line: #line)
        trackForMemoryLeaks(store, file: #filePath, line: #line)
        
        XCTAssertEqual(sut.currentProgress.completedPuzzleIDs, ["p1"])
    }
    
    func test_markCompleted_delegatesToStoreAndPublishes() {
        let (sut, store) = makeSUT()
        
        var receivedProgress = [BeginnerProgress]()
        let cancellable = sut.publisher().sink { receivedProgress.append($0) }
        
        sut.markCompleted(puzzleID: "p1")
        
        XCTAssertEqual(store.messages, [.markCompleted("p1")])
        XCTAssertEqual(receivedProgress.count, 2)
        XCTAssertEqual(receivedProgress[0].completedPuzzleIDs, [])
        XCTAssertEqual(receivedProgress[1].completedPuzzleIDs, ["p1"])
        
        cancellable.cancel()
    }
    
    func test_clearProgress_delegatesToStoreAndPublishes() {
        let store = BeginnerProgressStoreSpy()
        store.currentProgress = BeginnerProgress(completedPuzzleIDs: ["p1"])
        let sut = BeginnerProgressAdapter(store: store)
        
        trackForMemoryLeaks(sut, file: #filePath, line: #line)
        trackForMemoryLeaks(store, file: #filePath, line: #line)
        
        var receivedProgress = [BeginnerProgress]()
        let cancellable = sut.publisher().sink { receivedProgress.append($0) }
        
        sut.clearProgress()
        
        XCTAssertEqual(store.messages, [.clearProgress])
        XCTAssertEqual(receivedProgress.count, 2)
        XCTAssertEqual(receivedProgress[0].completedPuzzleIDs, ["p1"])
        XCTAssertEqual(receivedProgress[1].completedPuzzleIDs, [])
        
        cancellable.cancel()
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: BeginnerProgressAdapter, store: BeginnerProgressStoreSpy) {
        let store = BeginnerProgressStoreSpy()
        let sut = BeginnerProgressAdapter(store: store)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        
        return (sut, store)
    }
    
    private class BeginnerProgressStoreSpy: BeginnerProgressStore {
        enum Message: Equatable {
            case markCompleted(String)
            case clearProgress
        }
        
        private(set) var messages = [Message]()
        var currentProgress = BeginnerProgress(completedPuzzleIDs: [])
        
        func markCompleted(puzzleID: String) {
            messages.append(.markCompleted(puzzleID))
            var completed = currentProgress.completedPuzzleIDs
            completed.insert(puzzleID)
            currentProgress = BeginnerProgress(completedPuzzleIDs: completed)
        }
        
        func clearProgress() {
            messages.append(.clearProgress)
            currentProgress = BeginnerProgress(completedPuzzleIDs: [])
        }
    }
}
