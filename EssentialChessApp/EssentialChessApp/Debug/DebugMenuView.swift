//
//  DebugMenuView.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//

import SwiftUI
import EssentialChess
import EssentialChessUI

struct DebugMenuView: View {
    @EnvironmentObject var curriculumVM: CurriculumViewModel
    @EnvironmentObject var container: DependencyContainer
    
    var body: some View {
        Menu {
            Button("🚀 Unlock First Exam (Solve 100%)") {
                unlockFirstSection()
            }
            
            Button("🏆 Pass First Exam (Unlock Next Level)") {
                passFirstExam()
            }
            
            Button("⏳ Trigger 3-Hour Cooldown") {
                triggerCooldown()
            }
            
            Divider()
            
            Button("💣 Reset All Progress", role: .destructive) {
                resetProgress()
            }
            
            Button("🗑️ Hard Clean Store Data", role: .destructive) {
                hardCleanStoreData()
            }
        } label: {
            Image(systemName: "ladybug.fill")
                .font(.system(size: 18))
                .foregroundColor(.red)
                .padding(8)
                .background(Circle().fill(Color.red.opacity(0.15)))
            
            Text("Debug Menu")
                .foregroundColor(AppColors.textSecondary)
                .font(.system(size: 12, weight: .semibold))
        }
    }
    
    // MARK: - Debug Actions
    
    private func unlockFirstSection() {
        guard let firstSection = curriculumVM.sections.first else { return }
        var allPuzzleIDs = Set<String>()
        
        // Loop through all non-exam categories to collect every puzzle ID
        for category in firstSection.categories where !category.isExamMode {
            if let themes = category.subThemes {
                for theme in themes {
                    allPuzzleIDs.formUnion(theme.puzzles.map { $0.id })
                }
            }
            if let directPuzzles = category.puzzles {
                allPuzzleIDs.formUnion(directPuzzles.map { $0.id })
            }
        }
        
        // Inject to database, UI will react automatically
        container.progressAdapter.update { progress in
            progress.completedPuzzleIDs.formUnion(allPuzzleIDs)
        }
    }
    
    private func passFirstExam() {
        guard let firstSection = curriculumVM.sections.first,
              let examCategory = firstSection.categories.first(where: { $0.isExamMode }) else { return }
        
        container.progressAdapter.update { progress in
            progress.passedExamIDs.insert(examCategory.id)
        }
    }
    
    private func triggerCooldown() {
        guard let firstSection = curriculumVM.sections.first,
              let examCategory = firstSection.categories.first(where: { $0.isExamMode }) else { return }
        
        container.progressAdapter.update { progress in
            // Set failure time to right now
            progress.examFailureTimes[examCategory.id] = Date()
        }
    }
    
    private func resetProgress() {
        container.progressAdapter.update { progress in
            progress.completedPuzzleIDs.removeAll()
            progress.passedExamIDs.removeAll()
            progress.examFailureTimes.removeAll()
            progress.highestPuzzleStreak = 0
            progress.highestPuzzleStorm = 0
            progress.activePuzzleStreak = 0
            progress.onboardingComplete = false
        }
        container.beginnerProgressStore.clearProgress()
    }
    
    private func hardCleanStoreData() {
        // Clear iCloud Key-Value Store
        NSUbiquitousKeyValueStore.default.removeObject(forKey: "user_progress_cache")
        NSUbiquitousKeyValueStore.default.synchronize()
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "user_progress_cache")
        UserDefaults.standard.removeObject(forKey: "beginner_completed_puzzles")
        
        print("UbiquitousProgressStore & BeginnerStore completely cleaned. Please restart the app for full effect.")
    }
}
