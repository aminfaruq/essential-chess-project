//
//  SettingsViewModel.swift
//  EssentialChessUI
//

import Foundation
import EssentialChess
import Combine

public final class SettingsViewModel: ObservableObject {
    @Published public var isDailyReminderEnabled: Bool = false
    @Published public var isHapticEnabled: Bool = true
    @Published public var isSoundEnabled: Bool = true
    
    private var notificationStorage: NotificationStoragePort
    private let notificationScheduler: NotificationScheduler
    private var boardSettingsStorage: BoardSettingsStore
    
    public init(
        notificationStorage: NotificationStoragePort,
        notificationScheduler: NotificationScheduler,
        boardSettingsStorage: BoardSettingsStore
    ) {
        self.notificationStorage = notificationStorage
        self.notificationScheduler = notificationScheduler
        self.boardSettingsStorage = boardSettingsStorage
        
        self.isDailyReminderEnabled = notificationStorage.isDailyReminderEnabled
        self.isHapticEnabled = boardSettingsStorage.isHapticEnabled
        self.isSoundEnabled = boardSettingsStorage.isSoundEnabled
    }
    
    public func setDailyReminder(enabled: Bool) {
        guard isDailyReminderEnabled != enabled else { return }
        
        if enabled {
            enableReminder()
        } else {
            disableReminder()
        }
    }
    
    public func setHaptic(enabled: Bool) {
        guard isHapticEnabled != enabled else { return }
        isHapticEnabled = enabled
        boardSettingsStorage.isHapticEnabled = enabled
    }
    
    public func setSound(enabled: Bool) {
        guard isSoundEnabled != enabled else { return }
        isSoundEnabled = enabled
        boardSettingsStorage.isSoundEnabled = enabled
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
