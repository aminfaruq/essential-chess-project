//
//  NotificationStoragePort.swift
//  EssentialChess
//

import Foundation

public protocol NotificationStoragePort {
    var isDailyReminderEnabled: Bool { get set }
}
