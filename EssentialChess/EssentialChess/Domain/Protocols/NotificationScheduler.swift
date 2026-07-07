//
//  NotificationScheduler.swift
//  EssentialChess
//

import Foundation

public protocol NotificationScheduler {
    func requestPermission(completion: @escaping (Bool) -> Void)
    func scheduleDailyReminder(hour: Int, minute: Int, title: String, body: String)
    func cancelDailyReminder()
}
