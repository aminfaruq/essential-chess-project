//
//  UserDefaultsTabAdapterTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 14/06/26.
//

import XCTest
@testable import EssentialChess

final class UserDefaultsTabStoreTests: XCTestCase {
    
    private let testSuiteName = "com.essentialchess.test.tabadapter"
    private let storageKey = "selectedAppTab"

    override func tearDown() {
        super.tearDown()
        // Clean up any remaining data just to be safe
        UserDefaults().removePersistentDomain(forName: testSuiteName)
    }

    func test_savedTab_deliversCurriculumByDefaultWhenStorageIsEmpty() {
        let (sut, _) = makeSUT()
        
        XCTAssertEqual(sut.savedTab, .curriculum, "Expected default tab to be .curriculum when no data is saved.")
    }

    func test_savedTab_deliversCurriculumWhenStorageHasInvalidData() {
        let (sut, testDefaults) = makeSUT()
        testDefaults.set("invalid_tab_string", forKey: storageKey)
        
        XCTAssertEqual(sut.savedTab, .curriculum, "Expected default tab to be .curriculum when storage contains an unmapped string.")
    }

    func test_savedTab_deliversSavedTabSuccessfully() {
        let (sut, _) = makeSUT()
        
        sut.savedTab = .puzzleMix
        XCTAssertEqual(sut.savedTab, .puzzleMix, "Expected to retrieve .puzzleMix immediately after saving it.")
        
        sut.savedTab = .settings
        XCTAssertEqual(sut.savedTab, .settings, "Expected to retrieve .settings immediately after saving it.")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: UserDefaultsTabStore, testDefaults: UserDefaults) {
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        testDefaults.removePersistentDomain(forName: testSuiteName) // Clean slate
        
        let sut = UserDefaultsTabStore(defaults: testDefaults)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        
        addTeardownBlock { [weak testDefaults] in
            testDefaults?.removePersistentDomain(forName: "com.essentialchess.test.tabadapter")
        }
        
        return (sut, testDefaults)
    }
}
