//
//  ViewFactory.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 14/06/26.
//

import SwiftUI
import Combine
import EssentialChess
import EssentialChessUI

/// Handles routing and creating complex sub-views, completely decoupling navigation from AppComposer.
@MainActor
public final class ViewFactory: ObservableObject {
    private let container: DependencyContainer
    private var cachedCurriculum: Curriculum?
    
    @Published public var loadError: String?
    
    public init(container: DependencyContainer) {
        self.container = container
    }
    
    public func cache(curriculum: Curriculum) {
        self.cachedCurriculum = curriculum
    }
    
    // MARK: - Onboarding Presentation Factory
    
    public func fetchPlacementViewModel(
        onFinishedTest: @escaping (Double) -> Void,
        onReady: @escaping (OnboardingViewModel) -> Void
    ) {
        guard let loader = container.mixPoolLoader else {
            loadError = "Puzzle data not found. Please reinstall the app."
            return
        }
        
        loadError = nil
        
        loader.load {  [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                let allPuzzles: [Puzzle]
                
                switch result {
                case .success(let mixPool):
                    allPuzzles = mixPool.difficultyTiers.flatMap { $0.puzzles }
                case .failure(let error):
                    self.loadError = "Failed to load puzzles: \(error.localizedDescription)"
                    allPuzzles = []
                }
                
                let viewModel = OnboardingViewModel(
                    pool: allPuzzles,
                    totalPuzzles: 15,
                    initialRating: 1000.0,
                    calculateRating: { currentRating, puzzleRating, isCorrect in
                        return RatingCalculator().calculatePlacementRating(
                            current: currentRating,
                            puzzleRating: puzzleRating,
                            isCorrect: isCorrect
                        )
                    },
                    onComplete: onFinishedTest
                )
                
                onReady(viewModel)
            }
        }
    }
    
    // MARK: - Puzzle Mix Factory
    
    public func fetchPuzzleMixViewModel(
        onReady: @escaping (PuzzleMixViewModel) -> Void
    ) {
        guard let loader = container.mixPoolLoader else {
            loadError = "Puzzle data not found. Please reinstall the app."
            return
        }
        
        loadError = nil
        
        loader.load { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                let pool: [Puzzle]
                switch result {
                case .success(let mixPool):
                    pool = mixPool.difficultyTiers.flatMap { $0.puzzles }
                case .failure(let error):
                    self.loadError = "Failed to load puzzles: \(error.localizedDescription)"
                    pool = []
                }
                
                let progress = self.container.progressAdapter.currentProgress
                
                let viewModel = PuzzleMixViewModel(
                    pool: pool,
                    hiddenRating: progress.hiddenRating,
                    actualRating: progress.actualRating,
                    hasSeenHintWarning: UserDefaults.standard.bool(forKey: "hasSeenHintWarning"),
                    calculateRating: { currentRating, puzzleRating, isCorrect in
                        return RatingCalculator().calculateRegularRating(
                            current: currentRating,
                            puzzleRating: puzzleRating,
                            isCorrect: isCorrect
                        )
                    },
                    saveActualRating: { newRating in
                        self.container.progressAdapter.update { progress in
                            progress.actualRating = newRating
                        }
                    },
                    saveHasSeenHintWarning: { hasSeen in
                        UserDefaults.standard.set(hasSeen, forKey: "hasSeenHintWarning")
                    },
                    onPuzzleSolved: {
                        //MARK: Daily streak
                        self.container.progressAdapter.update { progress in
                            progress.recordActivity()
                        }
                    }
                )
                
                onReady(viewModel)
            }
        }
    }
    
    // MARK: - Puzzle Streak Factory
    
    public func fetchPuzzleStreakViewModel(
        onReady: @escaping (PuzzleStreakViewModel) -> Void
    ) {
        guard let loader = container.mixPoolLoader else {
            loadError = "Puzzle data not found. Please reinstall the app."
            return
        }
        
        loadError = nil
        
        loader.load { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                let pool: [Puzzle]
                switch result {
                case .success(let mixPool):
                    pool = mixPool.difficultyTiers.flatMap { $0.puzzles }
                case .failure(let error):
                    self.loadError = "Failed to load puzzles: \(error.localizedDescription)"
                    pool = []
                }
                
                let progress = self.container.progressAdapter.currentProgress
                
                let viewModel = PuzzleStreakViewModel(
                    pool: pool,
                    activeStreak: progress.activePuzzleStreak,
                    activeUsedIDs: progress.activePuzzleStreakUsedIDs,
                    highestStreak: progress.highestPuzzleStreak,
                    onStreakUpdated: { newStreak, usedIDs in
                        self.container.progressAdapter.update { progress in
                            progress.activePuzzleStreak = newStreak
                            progress.activePuzzleStreakUsedIDs = usedIDs
                        }
                    },
                    onSessionFinished: { finalStreak in
                        self.container.progressAdapter.update { progress in
                            if finalStreak > progress.highestPuzzleStreak {
                                progress.highestPuzzleStreak = finalStreak
                            }
                        }
                    },
                    updateDailyLimits: { _, _ in },
                    onPuzzleSolved: {
                        //MARK: Daily streak
                        self.container.progressAdapter.update { progress in
                            progress.recordActivity()
                        }
                    }
                )
                
                onReady(viewModel)
            }
        }
    }
    
    // MARK: - Puzzle Storm Factory
    
    public func fetchPuzzleStormViewModel(
        onReady: @escaping (PuzzleStormViewModel) -> Void
    ) {
        guard let loader = container.mixPoolLoader else {
            loadError = "Puzzle data not found. Please reinstall the app."
            return
        }
        
        loadError = nil
        
        loader.load { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                let pool: [Puzzle]
                switch result {
                case .success(let mixPool):
                    pool = mixPool.difficultyTiers.flatMap { $0.puzzles }
                case .failure(let error):
                    self.loadError = "Failed to load puzzles: \(error.localizedDescription)"
                    pool = []
                }
                
                let progress = self.container.progressAdapter.currentProgress
                
                let viewModel = PuzzleStormViewModel(
                    pool: pool,
                    highestScore: progress.highestPuzzleStorm,
                    onScoreUpdated: { newHighestScore in
                        self.container.progressAdapter.update { progress in
                            progress.highestPuzzleStorm = newHighestScore
                        }
                    },
                    onSessionFinished: { _ in
                        // Handled via onScoreUpdated for now, but could be useful for analytics
                    },
                    updateDailyLimits: { _, _ in },
                    onPuzzleSolved: {
                        //MARK: Daily streak
                        self.container.progressAdapter.update { progress in
                            progress.recordActivity()
                        }
                    }
                )
                
                onReady(viewModel)
            }
        }
    }
    
    // MARK: - Curriculum Navigation Factory
    
    public func makePuzzleSessionView(title: String, puzzles: [PuzzleUIModel]) -> some View {
        // Convert from UI model (dumb) to Domain model (smart)
        let domainPuzzles = puzzles.map { p in
            Puzzle(id: p.id, fen: p.fen, moves: p.moves, rating: p.rating, tags: p.tags)
        }
        
        // Get historical progress data
        let currentCompletedIDs = container.progressAdapter.currentProgress.completedPuzzleIDs
        
        let boardVM = PuzzleBoardViewModel(
            puzzles: domainPuzzles,
            initialCompletedIDs: currentCompletedIDs,
            onPuzzleSolved: { [weak self] solvedID in
                self?.container.progressAdapter.update { progress in
                    progress.completedPuzzleIDs.insert(solvedID)
                    
                    //MARK: Daily streak
                    progress.recordActivity()
                }
            }
        )
        
        return PuzzleSessionView(
            categoryTitle: title,
            boardVM: boardVM,
            onSessionClosed: { }
        )
    }
    
    // MARK: - Exam Navigation Factory
    
    public func makeExamSessionView(for categoryID: String, title: String) -> some View {
        var examPuzzles: [Puzzle] = []
        
        // 1. Extract the original Puzzle data based on the exam category ID
        if let sections = cachedCurriculum?.sections {
            for section in sections {
                if let examCategory = section.categories.first(where: { $0.id == categoryID }),
                   let puzzles = examCategory.puzzles {
                    examPuzzles = puzzles
                    break
                }
            }
        }
        
        // 2. Randomize the question bank and take a maximum of 10 questions for the Exam
        let shuffledBank = Array(examPuzzles.shuffled().prefix(10))
        
        // 3. Build ViewModel with pure Callback to Database
        let examVM = ExamViewModel(
            puzzles: shuffledBank,
            onPassed: { [weak self] in
                // Save the category ID to the list of passed exams
                self?.container.progressAdapter.update { progress in
                    progress.passedExamIDs.insert(categoryID)
                    
                    //MARK: Daily streak
                    progress.recordActivity()
                }
            },
            onFailed: { [weak self] in
                // Record the failure time to calculate the cooldown
                self?.container.progressAdapter.update { progress in
                    progress.examFailureTimes[categoryID] = Date()
                }
            }
        )
        
        return ExamView(
            categoryTitle: title,
            examVM: examVM
        )
    }
}
