//
//  CurriculumCoordinatorView.swift
//  EssentialChessApp
//
//  Created by App on 21/08/26.
//

import SwiftUI
import EssentialChess
import EssentialChessUI

public struct CurriculumCoordinatorView: View {
    @StateObject private var router: CurriculumRouter
    @EnvironmentObject var viewFactory: ViewFactory
    @EnvironmentObject var container: DependencyContainer
    
    @Binding var scrollToTopTrigger: Int
    
    public init(
        router: CurriculumRouter = CurriculumRouter(),
        scrollToTopTrigger: Binding<Int> = .constant(0)
    ) {
        _router = StateObject(wrappedValue: router)
        self._scrollToTopTrigger = scrollToTopTrigger
    }
    
    public var body: some View {
        NavigationStack(path: $router.path) {
            CurriculumView(
                scrollToTopTrigger: $scrollToTopTrigger,
                onSelectSection: { section in
                    router.navigate(to: .sectionDetail(section))
                }
            )
            .navigationDestination(for: CurriculumRoute.self) { route in
                switch route {
                case .sectionDetail(let section):
                    SectionDetailView(
                        model: section,
                        onSelectTheme: { theme in
                            if theme.isBeginnerMode {
                                let completed = container.beginnerProgressStore.currentProgress.completedPuzzleIDs
                                let initialIndex = theme.puzzles.firstIndex(where: { !completed.contains($0.id) }) ?? 0
                                router.navigate(to: .learnPiecesSession(
                                    themeId: theme.id,
                                    title: theme.title,
                                    puzzles: theme.puzzles,
                                    initialIndex: initialIndex
                                ))
                            } else {
                                router.navigate(to: .puzzleSession(
                                    title: theme.title,
                                    puzzles: theme.puzzles
                                ))
                            }
                        },
                        onSelectExam: { examCategory in
                            router.presentExam(examCategory)
                        }
                    )
                    
                case .puzzleSession(let title, let puzzles):
                    viewFactory.makePuzzleSessionView(title: title, puzzles: puzzles)
                    
                case .learnPiecesSession(let themeId, let title, let puzzles, let initialIndex):
                    LearnPiecesPuzzleSessionView(
                        themeId: themeId,
                        title: title,
                        puzzles: puzzles,
                        initialIndex: initialIndex
                    )
                }
            }
            .fullScreenCover(item: $router.presentedExamCategory) { examCategory in
                viewFactory.makeExamSessionView(for: examCategory.id, title: examCategory.title)
            }
        }
    }
}
