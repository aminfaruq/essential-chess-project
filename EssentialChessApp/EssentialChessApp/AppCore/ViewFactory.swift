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
public final class ViewFactory: ObservableObject {
    private let container: DependencyContainer
    private var cachedCurriculum: Curriculum?
    
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
        guard let loader = container.mixPoolLoader else { return }
        
        loader.load { result in
            DispatchQueue.main.async {
                let placementPuzzles: [Puzzle]
                
                switch result {
                case .success(let mixPool):
                    let allPuzzles = mixPool.difficultyTiers.flatMap { $0.puzzles }
                    placementPuzzles = Array(allPuzzles.shuffled().prefix(15))
                case .failure(_):
                    placementPuzzles = [] // Fallback to empty if reading fails
                }
                
                let viewModel = OnboardingViewModel(
                    puzzles: placementPuzzles,
                    initialRating: 1000.0,
                    calculateRating: { currentRating, _, isCorrect in
                        // Real ELO calculation logic can be placed here
                        let gain = isCorrect ? 32.0 : -32.0
                        return max(100.0, currentRating + gain)
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
        guard let loader = container.mixPoolLoader else { return }
        
        loader.load { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                let pool: [Puzzle]
                switch result {
                case .success(let mixPool):
                    pool = mixPool.difficultyTiers.flatMap { $0.puzzles }
                case .failure(_):
                    pool = []
                }
                
                let progress = self.container.progressAdapter.currentProgress
                
                let viewModel = PuzzleMixViewModel(
                    pool: pool,
                    hiddenRating: progress.hiddenRating,
                    actualRating: progress.actualRating,
                    checkIsPro: { [weak self] in
                        self?.container.progressAdapter.currentProgress.isPro ?? false
                    },
                    dailyPuzzleMixCount: progress.dailyPuzzleMixCount,
                    lastPuzzleMixDate: progress.lastPuzzleMixDate,
                    hasSeenHintWarning: UserDefaults.standard.bool(forKey: "hasSeenHintWarning"),
                    calculateRating: { currentRating, puzzleRating, isCorrect in
                        return RatingCalculator().calculatePlacementRating(
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
                    },
                    updateDailyLimits: { count, date in
                        self.container.progressAdapter.update { progress in
                            progress.dailyPuzzleMixCount = count
                            progress.lastPuzzleMixDate = date
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
