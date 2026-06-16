//
//  CurriculumViewModel.swift
//  EssentialChess
//
//  Created by Amin faruq on 11/06/26.
//

import Foundation
import Combine
import EssentialChess

// MARK: - Presentation Models (Dumb UI Models)

public struct SectionUIModel: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let eloRange: String
    public let progress: Double
    public let isUnlocked: Bool
    public let isPremiumLocked: Bool
    public let categories: [CategoryUIModel]
}

public struct CategoryUIModel: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let progress: Double
    public let isExamMode: Bool
    public let description: String?
    public let totalPuzzles: Int?
    public let puzzles: [PuzzleUIModel]?
    public let subThemes: [SubThemeUIModel]?
    public let examState: ExamUIState?
}

public enum ExamUIState: Equatable {
    case locked(reason: String)
    case unlocked(livesText: String)
    case passed(message: String)
    case onCooldown(availableIn: String)
}

public struct SubThemeUIModel: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let totalPuzzles: Int
    public let completedPuzzles: Int
    public let puzzles: [PuzzleUIModel]
    
    public init(id: String, title: String, totalPuzzles: Int, completedPuzzles: Int, puzzles: [PuzzleUIModel]) {
        self.id = id
        self.title = title
        self.totalPuzzles = totalPuzzles
        self.completedPuzzles = completedPuzzles
        self.puzzles = puzzles
    }
}

public struct PuzzleUIModel: Equatable {
    public let id: String
    public let fen: String
    public let moves: [String]
    public let rating: Int
    public let tags: [String]
    
    public init(id: String, fen: String, moves: [String], rating: Int, tags: [String]) {
        self.id = id
        self.fen = fen
        self.moves = moves
        self.rating = rating
        self.tags = tags
    }
}


public final class CurriculumViewModel: ObservableObject {
    
    @Published public private(set) var sections: [SectionUIModel] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String?
    
    private let curriculumPublisher: () -> AnyPublisher<Curriculum, Error>
    private let mixPoolPublisher: () -> AnyPublisher<MixPool, Error>
    private let progressPublisher: () -> AnyPublisher<UserProgress, Never>
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        curriculumPublisher: @escaping () -> AnyPublisher<Curriculum, Error>,
        mixPoolPublisher: @escaping () -> AnyPublisher<MixPool, Error>,
        progressPublisher: @escaping () -> AnyPublisher<UserProgress, Never>
    ) {
        self.curriculumPublisher = curriculumPublisher
        self.mixPoolPublisher = mixPoolPublisher
        self.progressPublisher = progressPublisher
    }
    
    public func load() {
        isLoading = true
        errorMessage = nil
        
        let dataZip = Publishers.Zip(curriculumPublisher(), mixPoolPublisher())
        
        // FIX 1: Match the Failure types using setFailureType
        Publishers.CombineLatest(dataZip, progressPublisher().setFailureType(to: Error.self))
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case let .failure(error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] combinedData, progress in
                    guard let self = self else { return }
                    let (curriculum, _) = combinedData
                    self.sections = self.mapToUIModels(curriculum: curriculum, progress: progress)
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Mapping Logic
    
    private func mapToUIModels(curriculum: Curriculum, progress: UserProgress) -> [SectionUIModel] {
        return curriculum.sections.enumerated().map { index, section in
            let isPremiumLocked = !progress.isPro && index > 0
            let isUnlocked = isPremiumLocked ? false : isSectionUnlocked(section, at: index, in: curriculum, progress: progress)
            let sectionProgress = CurriculumProgressTracker.progress(for: section, progress: progress)
            
            let categories = section.categories.map { category in
                mapCategory(category, sectionProgress: sectionProgress, isSectionUnlocked: isUnlocked, progress: progress)
            }
            
            return SectionUIModel(
                id: section.id,
                title: section.title,
                eloRange: "ELO \(section.eloRange)",
                progress: sectionProgress,
                isUnlocked: isUnlocked, 
                isPremiumLocked: isPremiumLocked,
                categories: categories
            )
        }
    }
    
    private func isSectionUnlocked(_ section: EloSection, at index: Int, in curriculum: Curriculum, progress: UserProgress) -> Bool {
        if progress.hiddenRating >= section.eloFloor { return true }
        if index == 0 { return true }
        
        let previousSection = curriculum.sections[index - 1]
        guard let previousExam = previousSection.categories.first(where: { $0.isExamMode }) else {
            return true
        }
        
        return progress.passedExamIDs.contains(previousExam.id)
    }
    
    private func mapCategory(_ category: EssentialChess.Category, sectionProgress: Double, isSectionUnlocked: Bool, progress: UserProgress) -> CategoryUIModel {
        let categoryProgress = CurriculumProgressTracker.progress(for: category, progress: progress)
        let examState = mapExamState(for: category, sectionProgress: sectionProgress, isSectionUnlocked: isSectionUnlocked, progress: progress)
        
        let puzzleToUI: (Puzzle) -> PuzzleUIModel = { p in
            PuzzleUIModel(id: p.id, fen: p.fen, moves: p.moves, rating: p.rating, tags: p.tags)
        }
        
        let subThemes: [SubThemeUIModel]? = category.subThemes?.map { st in
            let completedCount = st.puzzles.filter { progress.completedPuzzleIDs.contains($0.id) }.count
            return SubThemeUIModel(
                id: st.id,
                title: st.title,
                totalPuzzles: st.totalPuzzles,
                completedPuzzles: completedCount,
                puzzles: st.puzzles.map(puzzleToUI)
            )
        }
        
        return CategoryUIModel(
            id: category.id,
            title: category.title,
            progress: categoryProgress,
            isExamMode: category.isExamMode,
            description: category.description,
            totalPuzzles: category.totalPuzzles,
            puzzles: category.puzzles?.map(puzzleToUI),
            subThemes: subThemes,
            examState: examState
        )
    }
    
    private func mapExamState(for category: EssentialChess.Category, sectionProgress: Double, isSectionUnlocked: Bool, progress: UserProgress) -> ExamUIState? {
        guard category.isExamMode else { return nil }
        
        if progress.passedExamIDs.contains(category.id) {
            return .passed(message: "Passed — section unlocked!")
        }
        if !isSectionUnlocked {
            return .locked(reason: "Complete previous section to unlock")
        }
        if sectionProgress < 0.99 {
            return .locked(reason: "Complete all themes to unlock")
        }
        if let failTime = progress.examFailureTimes[category.id], Date().timeIntervalSince(failTime) < (3 * 3600) {
            return .onCooldown(availableIn: "On Cooldown")
        }
        
        return .unlocked(livesText: "3 lives · 10 random puzzles")
    }
}
