//
//  UserDefaultsLanguageStoreTests.swift
//  EssentialChessTests
//

import XCTest
import EssentialChess

final class UserDefaultsLanguageStoreTests: XCTestCase {

    private let testSuiteName = "com.essentialchess.test.languagestore"

    override func tearDown() {
        super.tearDown()
        UserDefaults().removePersistentDomain(forName: testSuiteName)
    }

    func test_languageCode_deliversEnByDefaultWhenStorageIsEmpty() {
        let (sut, _) = makeSUT()

        XCTAssertEqual(sut.languageCode, "en", "Expected default language code to be 'en' when no data is saved.")
    }

    func test_languageCode_deliversSavedValue() {
        let (sut, _) = makeSUT()

        sut.languageCode = "id"
        XCTAssertEqual(sut.languageCode, "id", "Expected to retrieve 'id' immediately after saving.")

        sut.languageCode = "fr"
        XCTAssertEqual(sut.languageCode, "fr", "Expected to retrieve 'fr' immediately after saving.")
    }

    func test_languageCode_persistsAcrossStoreInstances() {
        let (_, testDefaults) = makeSUT()
        let sut1 = UserDefaultsLanguageStore(userDefaults: testDefaults)
        sut1.languageCode = "ja"

        let sut2 = UserDefaultsLanguageStore(userDefaults: testDefaults)

        XCTAssertEqual(sut2.languageCode, "ja", "Expected new instance to read persisted value.")
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: UserDefaultsLanguageStore, testDefaults: UserDefaults) {
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        testDefaults.removePersistentDomain(forName: testSuiteName)

        let sut = UserDefaultsLanguageStore(userDefaults: testDefaults)

        trackForMemoryLeaks(sut, file: file, line: line)

        addTeardownBlock { [weak testDefaults] in
            testDefaults?.removePersistentDomain(forName: "com.essentialchess.test.languagestore")
        }

        return (sut, testDefaults)
    }
}
