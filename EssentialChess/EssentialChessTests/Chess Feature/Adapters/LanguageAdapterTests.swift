//
//  LanguageAdapterTests.swift
//  EssentialChessTests
//
//  Created by App on 11/06/26.
//

import XCTest
import Combine
import EssentialChess

final class LanguageAdapterTests: XCTestCase {
    
    func test_init_setsCurrentLanguageFromStore() {
        let (sut, _) = makeSUT(initialLanguage: "id")
        
        XCTAssertEqual(sut.currentLanguage, "id")
    }
    
    func test_load_updatesCurrentLanguageOnMainThread() {
        let (sut, store) = makeSUT(initialLanguage: "en")
        
        store.languageCode = "id"
        
        let exp = expectation(description: "Wait for load completion")
        sut.load()
        
        DispatchQueue.main.async {
            XCTAssertEqual(sut.currentLanguage, "id")
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_update_modifiesStoreAndCurrentLanguageOnMainThread() {
        let (sut, store) = makeSUT(initialLanguage: "en")
        
        let exp = expectation(description: "Wait for update completion")
        sut.update(languageCode: "id")
        
        DispatchQueue.main.async {
            XCTAssertEqual(sut.currentLanguage, "id")
            XCTAssertEqual(store.languageCode, "id")
            XCTAssertEqual(store.setCallCount, 1)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_update_doesNotUpdateIfLanguageIsSame() {
        let (sut, store) = makeSUT(initialLanguage: "en")
        
        let exp = expectation(description: "Wait for possible update")
        sut.update(languageCode: "en")
        
        DispatchQueue.main.async {
            XCTAssertEqual(store.setCallCount, 0, "Expected store not to be updated if language is the same")
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(initialLanguage: String, file: StaticString = #filePath, line: UInt = #line) -> (sut: LanguageAdapter, store: LanguageStoragePortSpy) {
        let store = LanguageStoragePortSpy(languageCode: initialLanguage)
        let sut = LanguageAdapter(store: store)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        
        return (sut, store)
    }
    
    private class LanguageStoragePortSpy: LanguageStore {
        var languageCode: String {
            didSet {
                setCallCount += 1
            }
        }
        
        private(set) var setCallCount = 0
        
        init(languageCode: String) {
            self.languageCode = languageCode
        }
    }
}
