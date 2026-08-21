//
//  DependencyContainerWiringTests.swift
//  EssentialChessAppTests
//
//  Created by Amin faruq on 20/08/26.
//

import XCTest
import EssentialChess
@testable import EssentialChessApp

@MainActor
final class DependencyContainerWiringTests: XCTestCase {

    func test_init_injectsAllAdaptersAndStores() async {
        let sut = makeContainer()

        XCTAssertNotNil(sut.themeAdapter)
        XCTAssertNotNil(sut.progressAdapter)
        XCTAssertNotNil(sut.beginnerProgressAdapter)
        XCTAssertNotNil(sut.languageAdapter)
        XCTAssertNotNil(sut.notificationStorage)
        XCTAssertNotNil(sut.notificationScheduler)
        XCTAssertNotNil(sut.boardSettingsStorage)
    }

    func test_init_withoutBundleURLs_createsNoFileLoaders() async {
        let sut = makeContainer()

        XCTAssertNil(sut.curriculumLoader)
        XCTAssertNil(sut.mixPoolLoader)
        XCTAssertNil(sut.beginnerCurriculumLoader)
    }

    func test_init_withBundleURLs_createsFileLoadersForEachResource() async {
        let currURL = makeTempFile()
        let mixURL = makeTempFile()
        let begURL = makeTempFile()
        defer {
            try? FileManager.default.removeItem(at: currURL)
            try? FileManager.default.removeItem(at: mixURL)
            try? FileManager.default.removeItem(at: begURL)
        }

        let sut = DependencyContainer(
            themeStore: UserDefaultsThemeStore(store: makeDefaults()),
            progressStore: UbiquitousProgressStore(),
            beginnerProgressStore: UserDefaultsBeginnerProgressStore(userDefaults: makeDefaults()),
            notificationStorage: UserDefaultsNotificationStore(userDefaults: makeDefaults()),
            notificationScheduler: UserNotificationsAdapter(),
            boardSettingsStorage: UserDefaultsBoardSettingsStore(userDefaults: makeDefaults()),
            languageStore: UserDefaultsLanguageStore(userDefaults: makeDefaults()),
            reader: LocalFileReader(),
            curriculumURL: currURL,
            mixPoolURL: mixURL,
            beginnerCurriculumURL: begURL
        )

        XCTAssertNotNil(sut.curriculumLoader)
        XCTAssertNotNil(sut.mixPoolLoader)
        XCTAssertNotNil(sut.beginnerCurriculumLoader)
    }

    // MARK: - Helpers

    private func makeContainer() -> DependencyContainer {
        DependencyContainer(
            themeStore: UserDefaultsThemeStore(store: makeDefaults()),
            progressStore: UbiquitousProgressStore(),
            beginnerProgressStore: UserDefaultsBeginnerProgressStore(userDefaults: makeDefaults()),
            notificationStorage: UserDefaultsNotificationStore(userDefaults: makeDefaults()),
            notificationScheduler: UserNotificationsAdapter(),
            boardSettingsStorage: UserDefaultsBoardSettingsStore(userDefaults: makeDefaults()),
            languageStore: UserDefaultsLanguageStore(userDefaults: makeDefaults()),
            reader: LocalFileReader(),
            curriculumURL: nil,
            mixPoolURL: nil,
            beginnerCurriculumURL: nil
        )
    }

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "wiring_tests_\(UUID().uuidString)")!
    }

    private func makeTempFile() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        FileManager.default.createFile(atPath: url.path, contents: Data("{}".utf8))
        return url
    }
}