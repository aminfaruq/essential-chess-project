//
//  UserDefaultsBoardSettingsStoreTests.swift
//  EssentialChessTests
//

import XCTest
import EssentialChess

final class UserDefaultsBoardSettingsStoreTests: XCTestCase {

    private let testSuiteName = "com.essentialchess.test.boardsettingsstore"

    override func tearDown() {
        super.tearDown()
        UserDefaults().removePersistentDomain(forName: testSuiteName)
    }

    func test_isHapticEnabled_deliversTrueByDefault() {
        let (sut, _) = makeSUT()

        XCTAssertTrue(sut.isHapticEnabled, "Expected haptic to default to true via registered defaults.")
    }

    func test_isSoundEnabled_deliversTrueByDefault() {
        let (sut, _) = makeSUT()

        XCTAssertTrue(sut.isSoundEnabled, "Expected sound to default to true via registered defaults.")
    }

    func test_saveAndRetrieve_roundTrip() {
        let (sut, _) = makeSUT()

        sut.isHapticEnabled = false
        sut.isSoundEnabled = false

        XCTAssertFalse(sut.isHapticEnabled)
        XCTAssertFalse(sut.isSoundEnabled)

        sut.isHapticEnabled = true
        sut.isSoundEnabled = true

        XCTAssertTrue(sut.isHapticEnabled)
        XCTAssertTrue(sut.isSoundEnabled)
    }

    func test_persistsAcrossStoreInstances() {
        let (_, testDefaults) = makeSUT()
        let sut1 = UserDefaultsBoardSettingsStore(userDefaults: testDefaults)

        sut1.isHapticEnabled = false
        sut1.isSoundEnabled = false

        let sut2 = UserDefaultsBoardSettingsStore(userDefaults: testDefaults)

        XCTAssertFalse(sut2.isHapticEnabled, "Expected persisted haptic value, not registered default.")
        XCTAssertFalse(sut2.isSoundEnabled, "Expected persisted sound value, not registered default.")
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: UserDefaultsBoardSettingsStore, testDefaults: UserDefaults) {
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        testDefaults.removePersistentDomain(forName: testSuiteName)

        let sut = UserDefaultsBoardSettingsStore(userDefaults: testDefaults)

        trackForMemoryLeaks(sut, file: file, line: line)

        addTeardownBlock { [weak testDefaults] in
            testDefaults?.removePersistentDomain(forName: "com.essentialchess.test.boardsettingsstore")
        }

        return (sut, testDefaults)
    }
}
