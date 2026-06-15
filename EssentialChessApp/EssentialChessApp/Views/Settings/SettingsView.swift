//
//  SettingsView.swift
//  EssentialChessApp
//
//  Created by App on 11/06/26.
//

import SwiftUI
import EssentialChessUI
import EssentialChess

public struct SettingsView: View {
    @EnvironmentObject var container: DependencyContainer
    @EnvironmentObject var themeAdapter: ThemeAdapter
    @State private var showingResetAlert = false

    public init() {}
    
    private let pieceThemes: [(id: String, label: String)] = [
        ("default", "Standard"),
        ("alpha", "Alpha"),
        ("fantasy", "Fantasy"),
    ]

    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                List {
                    Section {
                        ForEach(BoardThemeOption.allCases, id: \.self) { option in
                            boardThemeRow(option)
                        }
                    } header: {
                        Text("Board Theme")
                            .foregroundColor(AppColors.textSecondary)
                            .font(.system(size: 12, weight: .semibold))
                    }

                    Section {
                        ForEach(pieceThemes, id: \.id) { theme in
                            pieceThemeRow(theme)
                        }
                    } header: {
                        Text("Piece Style")
                            .foregroundColor(AppColors.textSecondary)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            showingResetAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Reset All Progress")
                                    .fontWeight(.medium)
                            }
                        }
                        .foregroundColor(AppColors.red)
                        .hoverEffect(.highlight)
                    } header: {
                        Text("App Data")
                            .foregroundColor(AppColors.red)
                            .font(.system(size: 12, weight: .semibold))
                    }

                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Are you sure you want to reset all your progress?", isPresented: $showingResetAlert) {
                Button("No", role: .cancel) { }
                Button("Yes, Reset", role: .destructive) {
                    resetProgress()
                }
            } message: {
                Text("This action cannot be undone.")
            }

        }
    }
    
    private func boardThemeRow(_ option: BoardThemeOption) -> some View {
        let isSelected = themeAdapter.currentTheme.boardTheme == option
        return Button {
            themeAdapter.update { current in
                current = ThemeSettings(boardTheme: option, pieceTheme: current.pieceTheme)
            }
        } label: {
            HStack(spacing: 14) {
                BoardThemePreviewChip(option: option)
                Text(option.rawValue)
                    .foregroundColor(AppColors.textPrimary)
                    .font(.system(size: 16))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(AppColors.accent)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(AppColors.surface)
        .hoverEffect(.highlight)
    }
    
    private func pieceThemeRow(_ theme: (id: String, label: String)) -> some View {
        let isSelected = themeAdapter.currentTheme.pieceTheme == theme.id
        return Button {
            themeAdapter.update { current in
                current = ThemeSettings(boardTheme: current.boardTheme, pieceTheme: theme.id)
            }
        } label: {
            HStack(spacing: 14) {
                Image("\(theme.id)_wn")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)

                Text(theme.label)
                    .foregroundColor(AppColors.textPrimary)
                    .font(.system(size: 16))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(AppColors.accent)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(AppColors.surface)
        .hoverEffect(.highlight)
    }
    
    private func resetProgress() {
        container.progressAdapter.update { progress in
            progress.completedPuzzleIDs.removeAll()
            progress.passedExamIDs.removeAll()
            progress.examFailureTimes.removeAll()
            progress.onboardingComplete = false
        }
    }
}

// Two-square color swatch preview for a board theme
private struct BoardThemePreviewChip: View {
    let option: BoardThemeOption

    var body: some View {
        HStack(spacing: 2) {
            Color(
                red: option.lightSquareColor.red,
                green: option.lightSquareColor.green,
                blue: option.lightSquareColor.blue,
                opacity: option.lightSquareColor.alpha
            )
            .frame(width: 18, height: 18)
            
            Color(
                red: option.darkSquareColor.red,
                green: option.darkSquareColor.green,
                blue: option.darkSquareColor.blue,
                opacity: option.darkSquareColor.alpha
            )
            .frame(width: 18, height: 18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
