//
//  StreakViewModel.swift
//  EssentialChess
//
//  Created by Amin faruq on 14/06/26.
//

import EssentialChess
import Foundation
import Combine

public final class StreakViewModel: ObservableObject {
    @Published public private(set) var streakCount: Int = 0
    @Published public private(set) var isStreakActiveToday: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(progressPublisher: AnyPublisher<UserProgress, Never>, calendar: Calendar = .current) {
        progressPublisher
            .receive(on: DispatchQueue.main) // Ensure UI updates happen on main thread
            .sink { [weak self] progress in
                self?.streakCount = progress.currentStreak
                
                // Determine if the user has already played today to colorize the flame icon
                if let lastDate = progress.lastActivityDate {
                    self?.isStreakActiveToday = calendar.isDateInToday(lastDate)
                } else {
                    self?.isStreakActiveToday = false
                }
            }
            .store(in: &cancellables)
    }
}
