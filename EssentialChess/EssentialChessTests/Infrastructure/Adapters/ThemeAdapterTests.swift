//
//  ThemeAdapterTests.swift
//  EssentialChessTests
//

import XCTest
import Combine
import EssentialChess

final class ThemeAdapterTests: XCTestCase {
    
    func test_init_setsDefaultThemeSettings() {
        let (sut, _) = makeSUT()
        
        let expectedSettings = ThemeSettings(boardTheme: .brown, pieceTheme: "default")
        XCTAssertEqual(sut.currentTheme, expectedSettings)
    }
    
    func test_load_deliversSettingsFromStoreOnMainThread() {
        let (sut, store) = makeSUT()
        
        let expectedSettings = ThemeSettings(boardTheme: .blue, pieceTheme: "modern")
        
        let exp = expectation(description: "Wait for load completion")
        sut.load { [weak sut] in
            XCTAssertEqual(sut?.currentTheme, expectedSettings)
            XCTAssertTrue(Thread.isMainThread, "Expected completion to be called on main thread")
            exp.fulfill()
        }
        
        store.completeRetrieval(with: expectedSettings)
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_update_modifiesSettingsAndSavesToStore() {
        let (sut, store) = makeSUT()
        
        sut.update { settings in
            settings = ThemeSettings(boardTheme: .green, pieceTheme: "classic")
        }
        
        let expectedSettings = ThemeSettings(boardTheme: .green, pieceTheme: "classic")
        XCTAssertEqual(sut.currentTheme, expectedSettings)
        XCTAssertEqual(store.messages, [.insert(expectedSettings)])
    }
    
    func test_publisher_publishesSettingsOnUpdate() {
        let (sut, _) = makeSUT()
        
        var receivedSettings = [ThemeSettings]()
        let cancellable = sut.publisher().sink { receivedSettings.append($0) }
        
        sut.update { settings in
            settings = ThemeSettings(boardTheme: .green, pieceTheme: "classic")
        }
        
        XCTAssertEqual(receivedSettings, [
            ThemeSettings(boardTheme: .brown, pieceTheme: "default"),
            ThemeSettings(boardTheme: .green, pieceTheme: "classic")
        ])
        
        cancellable.cancel()
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: ThemeAdapter, store: ThemeStoreSpy) {
        let store = ThemeStoreSpy()
        let sut = ThemeAdapter(store: store)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        
        return (sut, store)
    }
    
    private class ThemeStoreSpy: ThemeLoader {
        enum Message: Equatable {
            case retrieve
            case insert(ThemeSettings)
        }
        
        private(set) var messages = [Message]()
        private var retrievalCompletions = [(ThemeLoader.RetrievalResult) -> Void]()
        private var insertionCompletions = [(ThemeLoader.InsertionResult) -> Void]()
        
        func retrieve(completion: @escaping (ThemeLoader.RetrievalResult) -> Void) {
            messages.append(.retrieve)
            retrievalCompletions.append(completion)
        }
        
        func completeRetrieval(with settings: ThemeSettings?, at index: Int = 0) {
            retrievalCompletions[index](.success(settings))
        }
        
        func completeRetrieval(with error: Error, at index: Int = 0) {
            retrievalCompletions[index](.failure(error))
        }
        
        func insert(_ settings: ThemeSettings, completion: @escaping (ThemeLoader.InsertionResult) -> Void) {
            messages.append(.insert(settings))
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
