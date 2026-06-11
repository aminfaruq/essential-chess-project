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
    @EnvironmentObject var composer: AppComposer
    let model: SectionUIModel
    
    private var nonExamCategories: [CategoryUIModel] { model.categories.filter { !$0.isExamMode } }
    private var examCategory: CategoryUIModel? { model.categories.first { $0.isExamMode } }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(nonExamCategories) { categoryModel in
                        NavigationLink(destination: CategoryDetailView(section: model, category: categoryModel)) {
                            CategoryCard(model: categoryModel)
                        }
                        .buttonStyle(.plain)
                        
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
        .navigationTitle(model.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct CategoryCard: View {
    let model: CategoryUIModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(model.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(Int(model.progress * 100))%")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(model.progress >= 1.0 ? AppColors.gold : AppColors.textSecondary)
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
    }
}

private struct ExamCard: View {
    @EnvironmentObject var composer: AppComposer
    @State private var showExam = false
    
    // Cukup menerima UI Model dari SectionDetailView
    let category: CategoryUIModel
    
    // Menerjemahkan ExamUIState ke dalam boolean visual tanpa mengubah logika UI lama
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
                        Text(category.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isPassed ? AppColors.gold : (isUnlocked ? AppColors.textPrimary : AppColors.locked))
                        Text(subtitleText)
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
        .fullScreenCover(isPresented: $showExam) {
            // Point to the Composer factory to assemble the Exam screen
            // Make sure you create this function in AppComposer later
            // composer.makeExamSessionView(for: category.id, title: category.title)
            composer.makeExamSessionView(for: category.id, title: category.title)
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
    @EnvironmentObject var composer: AppComposer
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
        let progress = composer.progressAdapter.currentProgress
        
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
