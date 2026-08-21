//
//  UserNotificationsAdapter.swift
//  EssentialChess
//

import Foundation
import UserNotifications
import OSLog

public protocol UserNotificationCenterProtocol {
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping @Sendable (Bool, Error?) -> Void)
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?)
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: UserNotificationCenterProtocol {}

@MainActor
public final class UserNotificationsAdapter: NotificationSchedulerLoader {
    private let center: UserNotificationCenterProtocol

    public init(center: UserNotificationCenterProtocol = UNUserNotificationCenter.current()) {
        self.center = center
    }
    
    public func requestPermission(completion: @escaping @MainActor (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            Task { @MainActor in
                if let error = error {
                    os_log(.error, "UserNotificationsAdapter: Permission request failed: %{public}@", error.localizedDescription)
                }
                completion(granted)
            }
        }
    }
    
    public func scheduleDailyReminder(hour: Int, minute: Int, title: String, body: String, completion: @escaping @MainActor (Error?) -> Void) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyPracticeReminder", content: content, trigger: trigger)
        
        center.add(request) { error in
            Task { @MainActor in
                if let error = error {
                    os_log(.error, "UserNotificationsAdapter: Failed to schedule reminder: %{public}@", error.localizedDescription)
                }
                completion(error)
            }
        }
    }
    
    public func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["dailyPracticeReminder"])
    }
}
