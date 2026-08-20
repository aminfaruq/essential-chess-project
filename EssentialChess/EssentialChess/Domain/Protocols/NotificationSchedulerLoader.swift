//
//  NotificationSchedulerLoader.swift
//  EssentialChess
//

import Foundation

public protocol NotificationSchedulerLoader {
    func requestPermission(completion: @escaping @MainActor (Bool) -> Void)
    func scheduleDailyReminder(hour: Int, minute: Int, title: String, body: String, completion: @escaping @MainActor (Error?) -> Void)
    func cancelDailyReminder()
}
