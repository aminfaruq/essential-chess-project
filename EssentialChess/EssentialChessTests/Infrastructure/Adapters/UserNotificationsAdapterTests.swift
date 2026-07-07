//
//  UserNotificationsAdapterTests.swift
//  EssentialChessTests
//

import XCTest
import UserNotifications
import EssentialChess

final class UserNotificationsAdapterTests: XCTestCase {

    func test_requestPermission_requestsAuthorizationWithCorrectOptions() {
        let (sut, center) = makeSUT()

        sut.requestPermission { _ in }

        XCTAssertEqual(center.requestAuthorizationCallCount, 1)
        XCTAssertEqual(center.requestedAuthorizationOptions, [.alert, .badge, .sound])
    }

    func test_requestPermission_deliversGrantedTrueWhenAuthorized() {
        let (sut, center) = makeSUT()
        var receivedGranted: Bool?
        let exp = expectation(description: "Wait for permission completion")

        sut.requestPermission { granted in
            receivedGranted = granted
            exp.fulfill()
        }

        center.completeAuthorization(withGranted: true)
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedGranted, true)
    }

    func test_requestPermission_deliversGrantedFalseWhenDenied() {
        let (sut, center) = makeSUT()
        var receivedGranted: Bool?
        let exp = expectation(description: "Wait for permission completion")

        sut.requestPermission { granted in
            receivedGranted = granted
            exp.fulfill()
        }

        center.completeAuthorization(withGranted: false)
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedGranted, false)
    }

    func test_requestPermission_deliversOnMainThread() {
        let (sut, center) = makeSUT()
        var completionThread: Thread?
        let exp = expectation(description: "Wait for permission completion")

        sut.requestPermission { _ in
            completionThread = Thread.current
            exp.fulfill()
        }

        center.completeAuthorization(withGranted: true)
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(completionThread, Thread.main)
    }

    func test_scheduleDailyReminder_createsNotificationWithCorrectContent() {
        let (sut, center) = makeSUT()

        sut.scheduleDailyReminder(hour: 8, minute: 30, title: "Practice", body: "Time to play!")

        XCTAssertEqual(center.addCallCount, 1)
        let request = center.addedRequests.first
        XCTAssertEqual(request?.content.title, "Practice")
        XCTAssertEqual(request?.content.body, "Time to play!")
        XCTAssertEqual(request?.content.sound, .default)
    }

    func test_scheduleDailyReminder_usesCorrectIdentifier() {
        let (sut, center) = makeSUT()

        sut.scheduleDailyReminder(hour: 8, minute: 30, title: "Practice", body: "Time!")

        let request = center.addedRequests.first
        XCTAssertEqual(request?.identifier, "dailyPracticeReminder")
    }

    func test_scheduleDailyReminder_setsCorrectTriggerHourAndMinute() {
        let (sut, center) = makeSUT()

        sut.scheduleDailyReminder(hour: 9, minute: 15, title: "Practice", body: "Time!")

        let request = center.addedRequests.first
        let trigger = request?.trigger as? UNCalendarNotificationTrigger
        XCTAssertEqual(trigger?.dateComponents.hour, 9)
        XCTAssertEqual(trigger?.dateComponents.minute, 15)
        XCTAssertEqual(trigger?.repeats, true)
    }

    func test_cancelDailyReminder_removesPendingRequestsWithCorrectIdentifier() {
        let (sut, center) = makeSUT()

        sut.cancelDailyReminder()

        XCTAssertEqual(center.removePendingCallCount, 1)
        XCTAssertEqual(center.removedIdentifiers, ["dailyPracticeReminder"])
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: UserNotificationsAdapter, center: UserNotificationCenterSpy) {
        let center = UserNotificationCenterSpy()
        let sut = UserNotificationsAdapter(center: center)

        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(center, file: file, line: line)

        return (sut, center)
    }

    private class UserNotificationCenterSpy: UserNotificationCenterProtocol {

        var requestAuthorizationCallCount = 0
        var requestedAuthorizationOptions: UNAuthorizationOptions = []
        private var authorizationCompletions = [(Bool, Error?) -> Void]()

        func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping @Sendable (Bool, Error?) -> Void) {
            requestAuthorizationCallCount += 1
            requestedAuthorizationOptions = options
            authorizationCompletions.append(completionHandler)
        }

        func completeAuthorization(withGranted granted: Bool, at index: Int = 0) {
            authorizationCompletions[index](granted, nil)
        }

        var addCallCount = 0
        var addedRequests = [UNNotificationRequest]()

        func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?) {
            addCallCount += 1
            addedRequests.append(request)
            completionHandler?(nil)
        }

        var removePendingCallCount = 0
        var removedIdentifiers: [String] = []

        func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
            removePendingCallCount += 1
            removedIdentifiers = identifiers
        }
    }
}
