//
//  MainNavigationViewModelTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 14/06/26.
//

import XCTest
import EssentialChess
@testable import EssentialChessUI

final class MainNavigationViewModelTests: XCTestCase {
    
    func test_init_loadsInitialStateFromStorageAndDoesNotSave() {
        // Given
        let spy = TabStoragePortSpy(initialTab: .puzzleMix)
        
        // When
        let sut = MainNavigationViewModel(tabStorage: spy)
        
        // Then
        XCTAssertEqual(sut.selectedTab, .puzzleMix, "ViewModel should load the initial state from the storage port.")
        XCTAssertTrue(spy.savedTabsHistory.isEmpty, "Initialization should use dropFirst() and NOT trigger a save to storage.")
    }
    
    func test_selectedTabChange_automaticallySavesToStorage() {
        // Given
        let spy = TabStoragePortSpy(initialTab: .curriculum)
        let sut = MainNavigationViewModel(tabStorage: spy)
        
        // When
        sut.selectedTab = .settings
        sut.selectedTab = .puzzleMix
        
        // Then
        XCTAssertEqual(spy.savedTabsHistory, [.settings, .puzzleMix], "ViewModel should save new tabs to storage in the exact order they were changed.")
    }
    
    func test_resetToCurriculum_setsTabToCurriculumAndSaves() {
        // Given
        let spy = TabStoragePortSpy(initialTab: .settings)
        let sut = MainNavigationViewModel(tabStorage: spy)
        
        // When
        sut.resetToCurriculum()
        
        // Then
        XCTAssertEqual(sut.selectedTab, .curriculum, "ViewModel state should reset to .curriculum.")
        XCTAssertEqual(spy.savedTabsHistory, [.curriculum], "The reset action should also trigger a save to storage.")
    }
    
    private final class TabStoragePortSpy: TabStoragePort {
        // Array to record all tabs that the ViewModel attempts to save
        var savedTabsHistory: [AppTab] = []
        
        // The underlying value
        private var _savedTab: AppTab
        
        init(initialTab: AppTab = .curriculum) {
            self._savedTab = initialTab
        }
        
        var savedTab: AppTab {
            get {
                return _savedTab
            }
            set {
                _savedTab = newValue
                // Record the action for verification in tests
                savedTabsHistory.append(newValue)
            }
        }
    }
}

