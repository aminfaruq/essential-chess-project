//
//  SettingsViewModel.swift
//  EssentialChessUI
//

import Foundation
import EssentialChess
import Combine

public final class SettingsViewModel: ObservableObject {
    @Published public var isDailyReminderEnabled: Bool = false
    
    private var notificationStorage: NotificationStoragePort
    private let notificationScheduler: NotificationScheduler
    
    public init(
        notificationStorage: NotificationStoragePort,
        notificationScheduler: NotificationScheduler
    ) {
        self.notificationStorage = notificationStorage
        self.notificationScheduler = notificationScheduler
        self.isDailyReminderEnabled = notificationStorage.isDailyReminderEnabled
    }
    
    public func setDailyReminder(enabled: Bool) {
        guard isDailyReminderEnabled != enabled else { return }
        
        if enabled {
            enableReminder()
        } else {
            disableReminder()
        }
    }
    
    private func enableReminder() {
        notificationScheduler.requestPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                self.notificationScheduler.scheduleDailyReminder(
                    hour: 8,
                    minute: 0,
                    title: "Time to Practice! ♟️",
                    body: "Complete your daily puzzles and maintain your learning streak."
                )
                self.updateStorage(enabled: true)
            } else {
                self.updateStorage(enabled: false)
            }
        }
    }
    
    private func disableReminder() {
        notificationScheduler.cancelDailyReminder()
        updateStorage(enabled: false)
    }
    
    private func updateStorage(enabled: Bool) {
        DispatchQueue.main.async {
            self.isDailyReminderEnabled = enabled
            self.notificationStorage.isDailyReminderEnabled = enabled
        }
    }
}
