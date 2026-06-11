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
    public let examState: ExamUIState?
}

public enum ExamUIState: Equatable {
    case locked(reason: String)
    case unlocked(livesText: String)
    case passed(message: String)
    case onCooldown(availableIn: String)
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
        return curriculum.sections.map { section in
            
            // FIX 2: Use the Pure Domain Service for all logic calculations
            let isUnlocked = CurriculumProgressTracker.isSectionUnlocked(section, progress: progress)
            let sectionProgress = CurriculumProgressTracker.progress(for: section, progress: progress)
            
            let categories: [CategoryUIModel] = section.categories.map { category in
                let categoryProgress = CurriculumProgressTracker.progress(for: category, progress: progress)
                
                var examState: ExamUIState? = nil
                if category.isExamMode {
                    if progress.passedExamIDs.contains(category.id) {
                        examState = .passed(message: "Passed — section unlocked!")
                    } else if !isUnlocked {
                        examState = .locked(reason: "Complete all themes to unlock")
                    } else if !CurriculumProgressTracker.canStartExam(categoryID: category.id, progress: progress) {
                        examState = .onCooldown(availableIn: "On Cooldown")
                    } else {
                        examState = .unlocked(livesText: "3 lives · 10 random puzzles")
                    }
                }
                
                return CategoryUIModel(
                    id: category.id,
                    title: category.title,
                    progress: categoryProgress,
                    isExamMode: category.isExamMode,
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
