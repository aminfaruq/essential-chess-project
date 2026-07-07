import Foundation
import Combine
import EssentialChess

public final class BeginnerCurriculumViewModel: ObservableObject {
    
    @Published public private(set) var sections: [SectionUIModel] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String?
    
    private let curriculumPublisher: () -> AnyPublisher<Curriculum, Error>
    private let progressPublisher: () -> AnyPublisher<BeginnerProgress, Never>
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        curriculumPublisher: @escaping () -> AnyPublisher<Curriculum, Error>,
        progressPublisher: @escaping () -> AnyPublisher<BeginnerProgress, Never>
    ) {
        self.curriculumPublisher = curriculumPublisher
        self.progressPublisher = progressPublisher
    }
    
    public func load() {
        isLoading = true
        errorMessage = nil
        
        Publishers.CombineLatest(curriculumPublisher(), progressPublisher().setFailureType(to: Error.self))
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case let .failure(error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] curriculum, progress in
                    guard let self = self else { return }
                    self.sections = self.mapToUIModels(curriculum: curriculum, progress: progress)
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Mapping Logic
    
    private func mapToUIModels(curriculum: Curriculum, progress: BeginnerProgress) -> [SectionUIModel] {
        return curriculum.sections.map { section in
            // For Beginner Curriculum, we calculate progress manually by scanning all puzzles
            let allPuzzlesInSection = section.categories.flatMap { $0.subThemes?.flatMap { $0.puzzles } ?? [] }
            let completedCount = allPuzzlesInSection.filter { progress.completedPuzzleIDs.contains($0.id) }.count
            let totalPuzzles = allPuzzlesInSection.count
            
            let sectionProgress = totalPuzzles > 0 ? Double(completedCount) / Double(totalPuzzles) : 0.0
            
            let categories = section.categories.map { category in
                mapCategory(category, progress: progress)
            }
            
            return SectionUIModel(
                id: section.id,
                title: section.title,
                eloRange: "ELO \(section.eloRange)",
                progress: sectionProgress,
                isUnlocked: true,
                categories: categories,
                isBeginnerMode: true
            )
        }
    }
    
    private func mapCategory(_ category: EssentialChess.Category, progress: BeginnerProgress) -> CategoryUIModel {
        let allPuzzlesInCategory = category.subThemes?.flatMap { $0.puzzles } ?? []
        let completedCount = allPuzzlesInCategory.filter { progress.completedPuzzleIDs.contains($0.id) }.count
        let totalPuzzles = allPuzzlesInCategory.count
        let categoryProgress = totalPuzzles > 0 ? Double(completedCount) / Double(totalPuzzles) : 0.0
        
        let puzzleToUI: (Puzzle) -> PuzzleUIModel = { p in
            PuzzleUIModel(id: p.id, fen: p.fen, moves: p.moves, rating: p.rating, tags: p.tags)
        }
        
        let subThemes: [SubThemeUIModel]? = category.subThemes?.map { st in
            let stCompletedCount = st.puzzles.filter { progress.completedPuzzleIDs.contains($0.id) }.count
            return SubThemeUIModel(
                id: st.id,
                title: st.title,
                totalPuzzles: st.totalPuzzles,
                completedPuzzles: stCompletedCount,
                puzzles: st.puzzles.map(puzzleToUI),
                isBeginnerMode: true
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
            examState: nil, // No exams in beginner mode
            isBeginnerMode: true
        )
    }
}
