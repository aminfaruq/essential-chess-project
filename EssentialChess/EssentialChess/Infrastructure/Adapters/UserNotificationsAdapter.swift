//
//  UserNotificationsAdapter.swift
//  EssentialChess
//

import Foundation
import UserNotifications

public final class UserNotificationsAdapter: NotificationScheduler {
    private let center: UNUserNotificationCenter
    
    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }
    
    public func requestPermission(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    public func scheduleDailyReminder(hour: Int, minute: Int, title: String, body: String) {
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
            if let error = error {
                print("Error scheduling daily reminder: \(error.localizedDescription)")
            }
        }
    }
    
    public func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["dailyPracticeReminder"])
    }
}
