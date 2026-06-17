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
    
    public let notificationStorage: NotificationStoragePort
    public let notificationScheduler: NotificationScheduler
    
    public let curriculumLoader: FileCurriculumLoader?
    public let mixPoolLoader: FileMixPoolLoader?
    
    public init() {
        let themeStore = UserDefaultsThemeStore()
        self.themeAdapter = ThemeAdapter(store: themeStore)
        
        let progressStore = UserDefaultsProgressStore()
        self.progressAdapter = ProgressAdapter(store: progressStore)
        
        self.notificationStorage = UserDefaultsNotificationStorage()
        self.notificationScheduler = UserNotificationsAdapter()
        
        let reader = LocalFileReader()
        
        if let currUrl = Bundle.main.url(forResource: "curriculum_final", withExtension: "json") {
            self.curriculumLoader = FileCurriculumLoader(url: currUrl, reader: reader)
        } else {
            self.curriculumLoader = nil
        }
        
        if let mixUrl = Bundle.main.url(forResource: "healthy_mix_pool", withExtension: "json") {
            self.mixPoolLoader = FileMixPoolLoader(url: mixUrl, reader: reader)
        } else {
            self.mixPoolLoader = nil
        }
    }
}
