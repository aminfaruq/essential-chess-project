//
//  AppComposerWiringTests.swift
//  EssentialChessAppTests
//
//  Created by Amin faruq on 20/08/26.
//

import XCTest
import EssentialChess
@testable import EssentialChessApp

@MainActor
final class AppComposerWiringTests: XCTestCase {

    func test_initWithContainer_usesSameContainerInstance() async {
        let container = makeContainer()

        let sut = AppComposer(container: container)

        XCTAssertTrue(sut.container === container)
    }

    func test_initWithContainer_wiresAllViewModels() async {
        let container = makeContainer()

        let sut = AppComposer(container: container)

        XCTAssertNotNil(sut.curriculumVM)
        XCTAssertNotNil(sut.beginnerVM)
        XCTAssertNotNil(sut.navigationVM)
        XCTAssertNotNil(sut.streakVM)
        XCTAssertNotNil(sut.settingsVM)
        XCTAssertNotNil(sut.viewFactory)
    }

    func test_initWithContainer_connectsProgressPublisherToStreakVM() async {
        let container = makeContainer()

        let sut = AppComposer(container: container)

        XCTAssertNotNil(sut.streakVM)
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
}