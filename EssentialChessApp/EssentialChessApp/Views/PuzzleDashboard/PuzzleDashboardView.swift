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
                    value: currentProg.actualRating != nil ? "\(Int(currentProg.actualRating!))" : "Unrated",
                    icon: "star.fill",
                    color: AppColors.gold
                )
                
                // Max Streak
                achievementCard(
                    title: "Best Streak",
                    value: "\(currentProg.highestPuzzleStreak)",
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
    
    private func achievementCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppColors.surface)
        .cornerRadius(16)
        // Add subtle shadow for premium feel
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
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
                        color: AppColors.accent
                    )
                }
                
                NavigationLink(destination: PuzzleStreakView()) {
                    menuCard(
                        title: "Puzzle Streak",
                        subtitle: "Solve as many puzzles as you can without making a mistake.",
                        icon: "flame.fill",
                        color: .orange
                    )
                }
                
                NavigationLink(destination: PuzzleStormView()) {
                    menuCard(
                        title: "Puzzle Storm",
                        subtitle: "Race against the clock to solve as many puzzles as possible.",
                        icon: "bolt.fill",
                        color: .yellow
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func menuCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer(minLength: 8)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}
