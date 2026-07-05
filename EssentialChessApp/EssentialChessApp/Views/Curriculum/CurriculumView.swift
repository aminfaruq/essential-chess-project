//
//  CurriculumView.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//

import SwiftUI
import EssentialChessUI 

public struct CurriculumView: View {
    @EnvironmentObject var curriculumVM: CurriculumViewModel
    //@EnvironmentObject var beginnerVM: BeginnerCurriculumViewModel
    
    @Binding var scrollToTopTrigger: Int
    
    public init(scrollToTopTrigger: Binding<Int> = .constant(0)) {
        self._scrollToTopTrigger = scrollToTopTrigger
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            /*ForEach(beginnerVM.sections) { sectionModel in
                                SectionCard(model: sectionModel)
                            }*/
                            
                            ForEach(curriculumVM.sections) { sectionModel in
                                SectionCard(model: sectionModel)
                            }
                        }
                        .id("top")
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                    .onChange(of: scrollToTopTrigger) { _, _ in
                        withAnimation {
                            proxy.scrollTo("top", anchor: .top)
                        }
                    }
                }
            }
            .navigationTitle("Chess Academy")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    StreakView()
                }
            }
        }
        
        .onAppear {
            if curriculumVM.sections.isEmpty {
                curriculumVM.load()
            }
            /*if beginnerVM.sections.isEmpty {
                beginnerVM.load()
            }*/
        }
    }
}

// MARK: - Subcomponents

private struct SectionCard: View {
    let model: SectionUIModel
    
    @State private var navigateToDetail = false
    @State private var showPaywall = false
    @State private var showLockedAlert = false
    
    var body: some View {
        Button {
            if model.isPremiumLocked {
                showPaywall = true
            } else if !model.isUnlocked {
                showLockedAlert = true
            } else {
                navigateToDetail = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                // Top Header: Title and Status Icon
                HStack(alignment: .center) {
                    Text(LocalizedStringKey(model.title))
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(model.isUnlocked ? AppColors.textPrimary : AppColors.locked)
                    
                    Spacer()
                    
                    if model.isUnlocked {
                        Text("\(Int(model.progress * 100))%")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(model.progress >= 1.0 ? AppColors.gold : AppColors.accent)
                    } else if model.isPremiumLocked {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.gold)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.locked)
                    }
                }
                
                // Elo Badge
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 11))
                    Text(LocalizedStringKey(model.eloRange))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundColor(model.isUnlocked ? AppColors.accent : AppColors.locked)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(model.isUnlocked ? AppColors.accent.opacity(0.15) : AppColors.surfaceHigh)
                )
                
                // Description
                if !model.description.isEmpty {
                    Text(LocalizedStringKey(model.description))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(model.isUnlocked ? AppColors.textSecondary : AppColors.locked.opacity(0.8))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Bottom: Progress Bar
                ProgressBarView(
                    progress: model.isUnlocked ? model.progress : 0,
                    height: 6,
                    fillColor: model.progress >= 1.0 ? AppColors.gold : AppColors.accent
                )
                .padding(.top, 4)
            }
            .padding(20)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        model.progress >= 1.0 ? AppColors.gold.opacity(0.4) : (model.isUnlocked ? AppColors.surfaceHigh : Color.clear), 
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .navigationDestination(isPresented: $navigateToDetail) {
            SectionDetailView(model: model)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Section Locked", isPresented: $showLockedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Complete the previous exam to unlock this section.")
        }
    }
}

// MARK: - Extensions

extension SectionUIModel {
    var description: String {
        switch id {
        case "sec_500_800":
            return "Master the basics. Recognize essential tactical patterns, checkmates, and endgames in simple, clear positions requiring 1 to 2 moves."
        case "sec_800_1200":
            return "Deepen your vision. Apply the exact same tactical motifs in more complex scenarios, requiring longer calculation and fewer obvious clues."
        case "sec_1200_1600":
            return "Find the hidden tactics. The themes remain the same, but you must now uncover them through sacrifices, preliminary moves, and deeper calculation."
        case "sec_1600_2000":
            return "True mastery. Execute standard tactical patterns hidden within complex variations, deep combinations, and unforgiving endgame positions."
        default:
            return "Start your chess journey. Learn how each piece moves, understand essential board rules, and grasp the absolute fundamentals of safe captures and defense."
        }
    }
}

