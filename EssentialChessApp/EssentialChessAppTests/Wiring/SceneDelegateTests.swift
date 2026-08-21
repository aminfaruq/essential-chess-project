//
//  SceneDelegateTests.swift
//  EssentialChessAppTests
//
//  Created by App on 21/08/26.
//

import XCTest
import UIKit
import SwiftUI
import EssentialChess
@testable import EssentialChessApp

@MainActor
final class SceneDelegateTests: XCTestCase {

    func test_init_withComposer_usesInjectedComposerInstance() {
        let composer = makeComposer()
        let sut = SceneDelegate(composer: composer)
        trackForMemoryLeaks(sut)

        XCTAssertTrue(sut.composer === composer)
    }

    // MARK: - Helpers

    private func makeComposer() -> AppComposer {
        let defaults = UserDefaults(suiteName: "scene_delegate_tests_\(UUID().uuidString)")!
        let container = DependencyContainer(
            themeStore: UserDefaultsThemeStore(store: defaults),
            progressStore: UserDefaultsProgressLoader(store: defaults),
            beginnerProgressStore: UserDefaultsBeginnerProgressStore(userDefaults: defaults),
            notificationStorage: UserDefaultsNotificationStore(userDefaults: defaults),
            notificationScheduler: UserNotificationsAdapter(),
            boardSettingsStorage: UserDefaultsBoardSettingsStore(userDefaults: defaults),
            languageStore: UserDefaultsLanguageStore(userDefaults: defaults),
            reader: LocalFileReader(),
            curriculumURL: nil,
            mixPoolURL: nil,
            beginnerCurriculumURL: nil
        )
        return AppComposer(container: container)
    }
}
