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
        //  Use enumerated() so we know which level index we are processing.
        return curriculum.sections.enumerated().map { index, section in
            
            let isUnlocked: Bool
            if index == 0 {
                // First level is always open
                isUnlocked = true
            } else {
                // For level 2 and beyond, peek at the previous level
                let previousSection = curriculum.sections[index - 1]
                
                // Search for exam category in previous level
                if let previousExam = previousSection.categories.first(where: { $0.isExamMode }) {
                    // This level is unlocked ONLY IF the previous level test has been passed
                    isUnlocked = progress.passedExamIDs.contains(previousExam.id)
                } else {
                    // If the previous level strangely didn't have a test, just open this level
                    isUnlocked = true
                }
            }
            
            // Progress of all non-exam categories in this section
            let sectionProgress = CurriculumProgressTracker.progress(for: section, progress: progress)
            
            let categories: [CategoryUIModel] = section.categories.map { category in
                let categoryProgress = CurriculumProgressTracker.progress(for: category, progress: progress)
                
                var examState: ExamUIState? = nil
                if category.isExamMode {
                    if progress.passedExamIDs.contains(category.id) {
                        examState = .passed(message: "Passed — section unlocked!")
                    }
                    else if !isUnlocked {
                        examState = .locked(reason: "Complete previous section to unlock")
                    }
                    else if sectionProgress < 0.99 {
                        examState = .locked(reason: "Complete all themes to unlock")
                    }
                    else if let failTime = progress.examFailureTimes[category.id], Date().timeIntervalSince(failTime) < (3 * 3600) {
                        examState = .onCooldown(availableIn: "On Cooldown")
                    }
                    else {
                        examState = .unlocked(livesText: "3 lives · 10 random puzzles")
                    }
                }
                
                // Map domain models to UI models
                let puzzleToUI: (Puzzle) -> PuzzleUIModel = { p in
                    PuzzleUIModel(id: p.id, fen: p.fen, moves: p.moves, rating: p.rating, tags: p.tags)
                }
                
                let subThemeToUI: (SubTheme) -> SubThemeUIModel = { st in
                    let completed = st.puzzles.filter { progress.completedPuzzleIDs.contains($0.id) }.count
                    return SubThemeUIModel(
                        id: st.id,
                        title: st.title,
                        totalPuzzles: st.totalPuzzles,
                        completedPuzzles: completed,
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
                    subThemes: category.subThemes?.map(subThemeToUI),
                    examState: examState
                )
            }
            
            return SectionUIModel(
                id: section.id,
                title: section.title,
                eloRange: "ELO \(section.eloRange)",
                progress: sectionProgress,
                isUnlocked: isUnlocked, 
                categories: categories
            )
        }
    }
}
