//
//  SectionDetailView.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//

import SwiftUI
import Combine
import EssentialChessUI
import EssentialChess

struct SectionDetailView: View {
    let model: SectionUIModel
    
    @EnvironmentObject var viewFactory: ViewFactory
    @State private var expandedCategoryID: String?
    @State private var refreshTrigger = UUID()
    @State private var lastToggleTime: Date = .distantPast
    @State private var isThemeSelected = false
    @State private var selectedTheme: SubThemeUIModel?
    
    private var nonExamCategories: [CategoryUIModel] { model.categories.filter { !$0.isExamMode } }
    private var examCategory: CategoryUIModel? { model.categories.first { $0.isExamMode } }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(nonExamCategories) { categoryModel in
                        ExpandableCategoryRow(
                            categoryModel: categoryModel,
                            isExpanded: expandedCategoryID == categoryModel.id,
                            onToggle: {
                                lastToggleTime = Date()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    if expandedCategoryID == categoryModel.id {
                                        expandedCategoryID = nil
                                    } else {
                                        expandedCategoryID = categoryModel.id
                                    }
                                }
                            },
                            onSelectTheme: { theme in
                                if Date().timeIntervalSince(lastToggleTime) > 0.45 {
                                    selectedTheme = theme
                                    isThemeSelected = true
                                }
                            },
                            refreshTrigger: refreshTrigger
                        )
                    }
                    
                    if let exam = examCategory {
                        ExamCard(category: exam)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(LocalizedStringKey(model.title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            refreshTrigger = UUID()
        }
        .navigationDestination(isPresented: $isThemeSelected) {
            if let theme = selectedTheme {
                viewFactory.makePuzzleSessionView(title: theme.title, puzzles: theme.puzzles)
            }
        }
    }
}

private struct ExpandableCategoryRow: View {
    @EnvironmentObject var viewFactory: ViewFactory
    let categoryModel: CategoryUIModel
    let isExpanded: Bool
    let onToggle: () -> Void
    let onSelectTheme: (SubThemeUIModel) -> Void
    let refreshTrigger: UUID
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                CategoryCard(model: categoryModel, isExpanded: isExpanded)
            }
            .buttonStyle(.plain)
            .zIndex(1) // Ensure the card is above the sliding list
            
            VStack(spacing: 0) {
                if isExpanded {
                    if let themes = categoryModel.subThemes {
                        VStack(spacing: 8) {
                            ForEach(themes) { theme in
                                Button {
                                    onSelectTheme(theme)
                                } label: {
                                    SectionSubThemeCard(subTheme: theme, refreshTrigger: refreshTrigger)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.leading, 16)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            .clipped() // Prevents rendering behind the card during animation
        }
    }
}

private struct CategoryCard: View {
    let model: CategoryUIModel
    var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(LocalizedStringKey(model.title))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(Int(model.progress * 100))%")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(model.progress >= 1.0 ? AppColors.gold : AppColors.textSecondary)
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.leading, 4)
            }
            ProgressBarView(
                progress: model.progress,
                height: 4,
                fillColor: model.progress >= 1.0 ? AppColors.gold : AppColors.accent
            )
        }
        .padding(18)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    model.progress >= 1.0 ? AppColors.gold.opacity(0.35) : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

private struct ExamCard: View {
    @EnvironmentObject var viewFactory: ViewFactory
    @State private var showExam = false
    
    let category: CategoryUIModel
    
    private var isPassed: Bool {
        if case .passed = category.examState { return true }; return false
    }
    
    private var isUnlocked: Bool {
        if case .locked = category.examState { return false }; return true
    }
    
    private var onCooldown: Bool {
        if case .onCooldown = category.examState { return true }; return false
    }
    
    var body: some View {
        Button {
            if isUnlocked && !isPassed && !onCooldown {
                showExam = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: isPassed ? "checkmark.seal.fill" : (isUnlocked ? "flame.fill" : "lock.fill"))
                        .foregroundColor(isPassed ? AppColors.gold : (isUnlocked ? AppColors.incorrect : AppColors.locked))
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(LocalizedStringKey(category.title))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isPassed ? AppColors.gold : (isUnlocked ? AppColors.textPrimary : AppColors.locked))
                        
                        Text(LocalizedStringKey(subtitleText))
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer()
                    if isUnlocked && !isPassed {
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                if onCooldown && !isPassed {
                    CooldownBadge(categoryID: category.id)
                }
            }
            .padding(18)
            .background(
                // Background color is reverted to passive when on cooldown
                isUnlocked && !isPassed && !onCooldown
                ? AppColors.incorrect.opacity(0.12)
                : AppColors.surface
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        // Border is removed if it is on cooldown
                        isUnlocked && !isPassed && !onCooldown ? AppColors.incorrect.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .disabled(!isUnlocked || isPassed)
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .fullScreenCover(isPresented: $showExam) {
            // Point to the Composer factory to assemble the Exam screen
            // Make sure you create this function in AppComposer later
            // composer.makeExamSessionView(for: category.id, title: category.title)
            viewFactory.makeExamSessionView(for: category.id, title: category.title)
        }
    }
    
    private var subtitleText: String {
        switch category.examState {
        case .locked(let reason): return reason
        case .unlocked(let livesText): return livesText
        case .passed(let message): return message
        case .onCooldown: return "3 lives · 10 random puzzles"
        case .none: return ""
        case .some: return ""
        }
    }
}

private struct CooldownBadge: View {
    @EnvironmentObject var container: DependencyContainer
    let categoryID: String
    
    @State private var remaining: TimeInterval = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if remaining > 0 {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                Text("Available in \(formattedTime)")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(AppColors.incorrect)
            .onAppear { updateRemaining() }
            .onReceive(timer) { _ in updateRemaining() }
        } else {
            EmptyView()
                .onAppear { updateRemaining() }
                .onReceive(timer) { _ in updateRemaining() }
        }
    }
    
    private func updateRemaining() {
        // Calculate remaining time directly from memory database
        let progress = container.progressAdapter.currentProgress
        
        if let failTime = progress.examFailureTimes[categoryID] {
            let cooldownPeriod: TimeInterval = 3 * 3600
            let elapsed = Date().timeIntervalSince(failTime)
            remaining = max(0, cooldownPeriod - elapsed)
        } else {
            remaining = 0
        }
    }
    
    private var formattedTime: String {
        let safeRemaining = max(0, remaining)
        
        let h = Int(safeRemaining) / 3600
        let m = (Int(safeRemaining) % 3600) / 60
        let s = Int(safeRemaining) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

private struct SectionSubThemeCard: View {
    @EnvironmentObject var container: DependencyContainer
    let subTheme: SubThemeUIModel
    let refreshTrigger: UUID
    
    private var completed: Int {
        _ = refreshTrigger
        let completedIDs = container.progressAdapter.currentProgress.completedPuzzleIDs
        return subTheme.puzzles.filter { completedIDs.contains($0.id) }.count
    }
    
    private var progress: Double {
        guard subTheme.totalPuzzles > 0 else { return 0.0 }
        return Double(completed) / Double(subTheme.totalPuzzles)
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon Indicator
            ZStack {
                Circle()
                    .fill(progress >= 1.0 ? AppColors.gold.opacity(0.15) : AppColors.accent.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: progress >= 1.0 ? "checkmark" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(progress >= 1.0 ? AppColors.gold : AppColors.accent)
                    .offset(x: progress >= 1.0 ? 0 : 1.5) // Center the play icon visually
            }
            
            // Text and Progress
            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStringKey(subTheme.title))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 10) {
                    ProgressBarView(
                        progress: progress,
                        height: 4,
                        fillColor: progress >= 1.0 ? AppColors.gold : AppColors.accent
                    )
                    
                    Text("\(completed)/\(subTheme.totalPuzzles)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(AppColors.surface.opacity(0.4)) // Subtle background to differentiate from parent
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    progress >= 1.0 ? AppColors.gold.opacity(0.4) : AppColors.surface,
                    lineWidth: 1
                )
        )
    }
}
