//
//  PuzzleDashboardView.swift
//  EssentialChessApp
//

import SwiftUI
import EssentialChess
import EssentialChessUI

public struct PuzzleDashboardView: View {
    @EnvironmentObject var composer: AppComposer
    @State private var progress: UserProgress?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Achievement Section
                        achievementSection
                        
                        // Menu Section
                        menuSection
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Puzzle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                if progress == nil {
                    progress = composer.container.progressAdapter.currentProgress
                }
            }
            .onReceive(composer.container.progressAdapter.publisher()) { newProgress in
                self.progress = newProgress
            }
        }
    }
    
    // MARK: - Subviews
    
    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.title2)
                .bold()
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 20)
            
            HStack(spacing: 12) {
                let currentProg = progress ?? composer.container.progressAdapter.currentProgress
                
                // Actual Rating
                achievementCard(
                    title: "Rating",
                    value: currentProg.actualRating != nil ? "\(Int(currentProg.actualRating!))" : String(localized: "Unrated"),
                    icon: "star.fill",
                    color: AppColors.gold
                )
                
                // Max Streak
                achievementCard(
                    title: "Best Streak",
                    value: currentProg.highestPuzzleStreak == 0 ? "\(currentProg.activePuzzleStreak)" : "\(currentProg.highestPuzzleStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                // Max Storm
                achievementCard(
                    title: "Best Storm",
                    value: "\(currentProg.highestPuzzleStorm)",
                    icon: "bolt.fill",
                    color: .yellow
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func achievementCard(title: LocalizedStringKey, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }
    
    private var menuSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Play Modes")
                .font(.title2)
                .bold()
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                NavigationLink(destination: PuzzleMixView()) {
                    menuCard(
                        title: "Puzzle Mix",
                        subtitle: "A mix of tactical themes to improve your overall vision.",
                        icon: "puzzlepiece.extension.fill",
                        color: AppColors.accent,
                        isNew: false
                    )
                }
                
                NavigationLink(destination: PuzzleStreakView()) {
                    menuCard(
                        title: "Puzzle Streak",
                        subtitle: "Solve as many puzzles as you can without making a mistake.",
                        icon: "flame.fill",
                        color: .orange,
                        isNew: false
                    )
                }
                
                NavigationLink(destination: PuzzleStormView()) {
                    menuCard(
                        title: "Puzzle Storm",
                        subtitle: "Race against the clock to solve as many puzzles as possible.",
                        icon: "bolt.fill",
                        color: .yellow,
                        isNew: false
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func menuCard(title: LocalizedStringKey, subtitle: LocalizedStringKey, icon: String, color: Color, isNew: Bool) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    if isNew {
                        Text("NEW")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(color.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
            }
            
            Spacer(minLength: 8)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary.opacity(0.4))
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
    }
}
