//
//  CategoryDetailView.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//
import SwiftUI
import Combine
import EssentialChess
import EssentialChessUI

//MARK: - NO LONGER USED
struct CategoryDetailView: View {
    @EnvironmentObject var viewFactory: ViewFactory
    let section: SectionUIModel
    let category: CategoryUIModel
    
    // Add a state trigger to force UI refresh when returning from navigation
    @State private var refreshTrigger = UUID()
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    if let themes = category.subThemes {
                        ForEach(themes) { theme in
                            NavigationLink(
                                destination: viewFactory.makePuzzleSessionView(title: theme.title, puzzles: theme.puzzles)
                            ) {
                                // Pass the trigger down to the card
                                SubThemeCard(subTheme: theme, refreshTrigger: refreshTrigger)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            // Fires exactly when the user backs out of PuzzleSessionView
            refreshTrigger = UUID()
        }
    }
}

private struct SubThemeCard: View {
    @EnvironmentObject var container: DependencyContainer
    let subTheme: SubThemeUIModel
    
    // Receive the trigger from the parent view
    let refreshTrigger: UUID
    
    private var completed: Int {
        // Register the trigger so SwiftUI knows to re-evaluate this block
        _ = refreshTrigger
        
        // Fetch the absolute latest progress directly from the adapter
        let completedIDs = container.progressAdapter.currentProgress.completedPuzzleIDs
        return subTheme.puzzles.filter { completedIDs.contains($0.id) }.count
    }
    
    private var progress: Double {
        guard subTheme.totalPuzzles > 0 else { return 0.0 }
        return Double(completed) / Double(subTheme.totalPuzzles)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(LocalizedStringKey(subTheme.title))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(completed)/\(subTheme.totalPuzzles)")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(progress >= 1.0 ? AppColors.gold : AppColors.textSecondary)
            }
            ProgressBarView(
                progress: progress,
                height: 4,
                fillColor: progress >= 1.0 ? AppColors.gold : AppColors.accent
            )
        }
        .padding(18)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    progress >= 1.0 ? AppColors.gold.opacity(0.35) : Color.clear,
                    lineWidth: 1
                )
        )
    }
}
