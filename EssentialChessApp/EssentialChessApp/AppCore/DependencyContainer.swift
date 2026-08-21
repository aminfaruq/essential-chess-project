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
@MainActor
public final class DependencyContainer: ObservableObject {
    public let progressAdapter: ProgressAdapter
    public let themeAdapter: ThemeAdapter
    
    private var cancellables = Set<AnyCancellable>()
    
    public let notificationStorage: NotificationStore
    public let notificationScheduler: NotificationSchedulerLoader
    public let boardSettingsStorage: BoardSettingsStore
    
    public let curriculumLoader: FileCurriculumLoader?
    public let mixPoolLoader: FileMixPoolLoader?
    public let beginnerCurriculumLoader: FileCurriculumLoader?
    public let beginnerProgressStore: UserDefaultsBeginnerProgressStore
    public let beginnerProgressAdapter: BeginnerProgressAdapter
    
    public let languageAdapter: LanguageAdapter
    
    public convenience init() {
        self.init(
            themeStore: UserDefaultsThemeStore(),
            progressStore: UbiquitousProgressStore(),
            beginnerProgressStore: UserDefaultsBeginnerProgressStore(),
            notificationStorage: UserDefaultsNotificationStore(),
            notificationScheduler: UserNotificationsAdapter(),
            boardSettingsStorage: UserDefaultsBoardSettingsStore(),
            languageStore: UserDefaultsLanguageStore(),
            reader: LocalFileReader(),
            curriculumURL: Bundle.main.url(forResource: "curriculum_final_v2", withExtension: "json"),
            mixPoolURL: Bundle.main.url(forResource: "healthy_mix_pool", withExtension: "json"),
            beginnerCurriculumURL: Bundle.main.url(forResource: "beginner_curriculum", withExtension: "json")
        )
    }

    public init(
        themeStore: ThemeLoader,
        progressStore: ProgressLoader,
        beginnerProgressStore: UserDefaultsBeginnerProgressStore,
        notificationStorage: NotificationStore,
        notificationScheduler: NotificationSchedulerLoader,
        boardSettingsStorage: BoardSettingsStore,
        languageStore: LanguageStore,
        reader: FileReaderLoader,
        curriculumURL: URL?,
        mixPoolURL: URL?,
        beginnerCurriculumURL: URL?
    ) {
        self.themeAdapter = ThemeAdapter(store: themeStore)
        
        self.progressAdapter = ProgressAdapter(store: progressStore)
        
        self.beginnerProgressStore = beginnerProgressStore
        self.beginnerProgressAdapter = BeginnerProgressAdapter(store: beginnerProgressStore)
        
        self.notificationStorage = notificationStorage
        self.notificationScheduler = notificationScheduler
        self.boardSettingsStorage = boardSettingsStorage
        
        if let currUrl = curriculumURL {
            self.curriculumLoader = FileCurriculumLoader(url: currUrl, reader: reader)
        } else {
            self.curriculumLoader = nil
        }
        
        if let mixUrl = mixPoolURL {
            self.mixPoolLoader = FileMixPoolLoader(url: mixUrl, reader: reader)
        } else {
            self.mixPoolLoader = nil
        }
        
        if let begUrl = beginnerCurriculumURL {
            self.beginnerCurriculumLoader = FileCurriculumLoader(url: begUrl, reader: reader)
        } else {
            self.beginnerCurriculumLoader = nil
        }
        
        self.languageAdapter = LanguageAdapter(store: languageStore)
        
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
