//
//  AppComposer.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//

import SwiftUI
import Combine
import EssentialChess
import EssentialChessUI

public final class AppComposer: ObservableObject {
    @Published public private(set) var isReady: Bool = false
    
    /// ViewModels
    public let curriculumVM: CurriculumViewModel
    public let navigationVM: MainNavigationViewModel
    public let streakVM: StreakViewModel

    /// Loaders
    private let curriculumLoader: FileCurriculumLoader?
    private let mixPoolLoader: FileMixPoolLoader?
    
    /// Adapters
    public let progressAdapter: ProgressAdapter
    public let themeAdapter: ThemeAdapter
    

    /// Models
    private var cachedCurriculum: Curriculum?

    
    public init() {
        let themeStore = UserDefaultsThemeStore()
        self.themeAdapter = ThemeAdapter(store: themeStore)
        
        let progressStore = UserDefaultsProgressStore()
        let adapter = ProgressAdapter(store: progressStore)
        self.progressAdapter = adapter
        self.streakVM = StreakViewModel(progressPublisher: adapter.publisher())
        
        let reader = LocalFileReader()
        
        if let currUrl = Bundle.main.url(forResource: "curriculum_final", withExtension: "json") {
            self.curriculumLoader = FileCurriculumLoader(url: currUrl, reader: reader)
        } else {
            self.curriculumLoader = nil
        }
        
        if let mixUrl = Bundle.main.url(forResource: "healthy_mix_pool", withExtension: "json") {
            self.mixPoolLoader = FileMixPoolLoader(url: mixUrl, reader: reader)
        } else {
            self.mixPoolLoader = nil
        }
        
        let validCurrLoader = self.curriculumLoader
        let validMixLoader = self.mixPoolLoader
        
        self.curriculumVM = CurriculumViewModel(
            curriculumPublisher: {
                if let loader = validCurrLoader {
                    return loader.publisher()
                }
                return Fail(error: FileCurriculumLoader.Error.invalidData).eraseToAnyPublisher()
            },
            mixPoolPublisher: {
                if let loader = validMixLoader {
                    return loader.publisher()
                }
                return Fail(error: FileMixPoolLoader.Error.invalidData).eraseToAnyPublisher()
            },
            progressPublisher: { [adapter] in adapter.publisher() }
        )
        
        let tabAdapter = UserDefaultsTabAdapter()
        self.navigationVM = MainNavigationViewModel(tabStorage: tabAdapter)
    }
    
    public func start() {
        curriculumLoader?.load { [weak self] result in
            if case let .success(curriculum) = result {
                self?.cachedCurriculum = curriculum
            }
        }
        
        progressAdapter.load { [weak self] in
            DispatchQueue.main.async {
                self?.isReady = true
                self?.curriculumVM.load()
            }
        }
        
        themeAdapter.load { }
    }
    
    // MARK: - Onboarding Presentation Factory
    
    public func fetchPlacementViewModel(
        onFinishedTest: @escaping (Double) -> Void,
        onReady: @escaping (OnboardingViewModel) -> Void
    ) {
        guard let loader = mixPoolLoader else { return }
        
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
    
    
    // MARK: - Curriculum Navigation Factory
    
    public func makePuzzleSessionView(title: String, puzzles: [PuzzleUIModel]) -> some View {
        // Convert from UI model (dumb) to Domain model (smart)
        let domainPuzzles = puzzles.map { p in
            Puzzle(id: p.id, fen: p.fen, moves: p.moves, rating: p.rating, tags: p.tags)
        }
        
        // Get historical progress data
        let currentCompletedIDs = progressAdapter.currentProgress.completedPuzzleIDs
        
        let boardVM = PuzzleBoardViewModel(
            puzzles: domainPuzzles,
            initialCompletedIDs: currentCompletedIDs,
            onPuzzleSolved: { [weak self] solvedID in
                self?.progressAdapter.update { progress in
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
                self?.progressAdapter.update { progress in
                    progress.passedExamIDs.insert(categoryID)
                }
            },
            onFailed: { [weak self] in
                // Record the failure time to calculate the cooldown
                self?.progressAdapter.update { progress in
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


