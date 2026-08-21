//
//  PuzzleCoordinatorView.swift
//  EssentialChessApp
//
//  Created by App on 21/08/26.
//

import SwiftUI

public struct PuzzleCoordinatorView: View {
    @StateObject private var router: PuzzleRouter
    
    public init(router: PuzzleRouter = PuzzleRouter()) {
        _router = StateObject(wrappedValue: router)
    }
    
    public var body: some View {
        NavigationStack(path: $router.path) {
            PuzzleDashboardView(
                onSelectMix: { router.navigate(to: .puzzleMix) },
                onSelectStreak: { router.navigate(to: .puzzleStreak) },
                onSelectStorm: { router.navigate(to: .puzzleStorm) }
            )
            .navigationDestination(for: PuzzleRoute.self) { route in
                switch route {
                case .puzzleMix:
                    PuzzleMixView()
                case .puzzleStreak:
                    PuzzleStreakView()
                case .puzzleStorm:
                    PuzzleStormView()
                }
            }
        }
    }
}
