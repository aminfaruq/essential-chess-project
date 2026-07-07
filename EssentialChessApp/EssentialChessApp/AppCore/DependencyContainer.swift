//
//  DependencyContainer.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 14/06/26.
//

import Foundation
import EssentialChess
import EssentialChessUI
import Combine

/// Holds all pure infrastructure adapters, loaders, and stores.
public final class DependencyContainer: ObservableObject {
    public let progressAdapter: ProgressAdapter
    public let themeAdapter: ThemeAdapter
    
    private var cancellables = Set<AnyCancellable>()
    
    public let notificationStorage: NotificationStore
    public let notificationScheduler: NotificationScheduler
    public let boardSettingsStorage: BoardSettingsStore
    
    public let curriculumLoader: FileCurriculumLoader?
    public let mixPoolLoader: FileMixPoolLoader?
    public let beginnerCurriculumLoader: FileCurriculumLoader?
    public let beginnerProgressStore: UserDefaultsBeginnerProgressStore
    
    public let languageAdapter: LanguageAdapter
    
    public init() {
        let themeStore = UserDefaultsThemeStore()
        self.themeAdapter = ThemeAdapter(store: themeStore)
        
        let progressStore = UbiquitousProgressStore()
        self.progressAdapter = ProgressAdapter(store: progressStore)
        
        self.beginnerProgressStore = UserDefaultsBeginnerProgressStore()
        
        self.notificationStorage = UserDefaultsNotificationStore()
        self.notificationScheduler = UserNotificationsAdapter()
        self.boardSettingsStorage = UserDefaultsBoardSettingsStore()
        
        let reader = LocalFileReader()
        
        if let currUrl = Bundle.main.url(forResource: "curriculum_final_v2", withExtension: "json") {
            self.curriculumLoader = FileCurriculumLoader(url: currUrl, reader: reader)
        } else {
            self.curriculumLoader = nil
        }
        
        if let mixUrl = Bundle.main.url(forResource: "healthy_mix_pool", withExtension: "json") {
            self.mixPoolLoader = FileMixPoolLoader(url: mixUrl, reader: reader)
        } else {
            self.mixPoolLoader = nil
        }
        
        if let begUrl = Bundle.main.url(forResource: "beginner_curriculum", withExtension: "json") {
            self.beginnerCurriculumLoader = FileCurriculumLoader(url: begUrl, reader: reader)
        } else {
            self.beginnerCurriculumLoader = nil
        }
        
        let languageStorage = UserDefaultsLanguageStore()
        self.languageAdapter = LanguageAdapter(store: languageStorage)
        
        setupUbiquitousSync()
    }
    
    private func setupUbiquitousSync() {
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .sink { [weak self] _ in
                // Real-time synchronization when other devices update the store
                self?.progressAdapter.load { }
            }
            .store(in: &cancellables)
    }
}
