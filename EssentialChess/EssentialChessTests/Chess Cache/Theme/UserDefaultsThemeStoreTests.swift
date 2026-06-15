//
//  UserDefaultsThemeStoreTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import XCTest
import EssentialChess

final class UserDefaultsThemeStoreTests: XCTestCase {
    
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
            case let .success(settings):
                XCTAssertNil(settings, "Expected empty cache to return nil")
            default:
                XCTFail("Expected successful empty retrieval, got \(result) instead")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let settings = ThemeSettings(boardTheme: .green, pieceTheme: "default")
        
        let insertionExpectation = expectation(description: "Wait for store insertion")
        sut.insert(settings) { result in
            if case let .failure(error) = result {
                XCTFail("Expected successful insertion, got \(error) instead")
            }
            insertionExpectation.fulfill()
        }
        wait(for: [insertionExpectation], timeout: 1.0)
        
        let retrievalExpectation = expectation(description: "Wait for store retrieval")
        sut.retrieve { result in
            switch result {
            case let .success(retrievedSettings):
                XCTAssertEqual(retrievedSettings, settings)
            default:
                XCTFail("Expected successful retrieval, got \(result) instead")
            }
            retrievalExpectation.fulfill()
        }
        
        wait(for: [retrievalExpectation], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> ThemeStore {
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        let sut = UserDefaultsThemeStore(store: testDefaults)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private let testSuiteName = "testUserDefaultsThemeStore"
    
    private func setupEmptyStoreState() {
        UserDefaults().removePersistentDomain(forName: testSuiteName)
    }
    
    private func undoStoreSideEffects() {
        UserDefaults().removePersistentDomain(forName: testSuiteName)
    }
}
