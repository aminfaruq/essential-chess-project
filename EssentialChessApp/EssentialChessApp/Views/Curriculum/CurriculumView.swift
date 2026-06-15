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
        }
    }
}

// MARK: - Subcomponents

private struct SectionCard: View {
    let model: SectionUIModel
    
    var body: some View {
        NavigationLink(destination: SectionDetailView(model: model)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(model.isUnlocked ? AppColors.textPrimary : AppColors.locked)
                        Text(model.eloRange)
                            .font(.system(size: 13))
                            .foregroundColor(model.isUnlocked ? AppColors.textSecondary : AppColors.locked.opacity(0.7))
                    }
                    Spacer()
                    if model.isUnlocked {
                        Text("\(Int(model.progress * 100))%")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(model.progress >= 1.0 ? AppColors.gold : AppColors.accent)
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundColor(AppColors.locked)
                    }
                }
                
                ProgressBarView(
                    progress: model.isUnlocked ? model.progress : 0,
                    height: 5,
                    fillColor: model.progress >= 1.0 ? AppColors.gold : AppColors.accent
                )
            }
            .padding(20)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(model.progress >= 1.0 ? AppColors.gold.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .disabled(!model.isUnlocked)
        .buttonStyle(.plain)
    }
}

