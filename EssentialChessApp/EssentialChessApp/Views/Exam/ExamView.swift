//
//  ExamView.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//

import SwiftUI
import EssentialChess
import EssentialChessUI

public struct ExamView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeAdapter: ThemeAdapter
    @EnvironmentObject var composer: AppComposer
    
    let categoryTitle: String
    
    @StateObject private var examVM: ExamViewModel
    @StateObject private var boardController = ChessBoardController()
    
    @State private var showMoveOnOverlay = false
    @State private var hasUsedHintForCurrentPuzzle = false
    
    public init(categoryTitle: String, examVM: ExamViewModel) {
        self.categoryTitle = categoryTitle
        self._examVM = StateObject(wrappedValue: examVM)
    }
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            switch examVM.phase {
            case .active:
                if let puzzle = examVM.currentPuzzle {
                    activeView(puzzle: puzzle)
                }
            case .passed:
                resultView(passed: true)
            case .failed:
                resultView(passed: false)
            @unknown default:
                resultView(passed: false)
            }
        }
    }
    
    // MARK: - Active View
    
    private func activeView(puzzle: Puzzle) -> some View {
        VStack(spacing: 0) {
            examHeader
            Spacer(minLength: 8)
            
            ProgressBarView(
                progress: examVM.totalPuzzles == 0 ? 0 : Double(examVM.solvedCount) / Double(examVM.totalPuzzles),
                height: 6, fillColor: AppColors.incorrect
            )
            .padding(.horizontal, 20)
            
            Spacer(minLength: 8)
            
            PuzzleBoardBridge(
                puzzle: puzzle,
                controller: boardController,
                onCompleted: {
                    examVM.handleCorrect()
                },
                onWrong: {
                    examVM.handleIncorrect()
                    if examVM.phase == .active {
                        showMoveOnOverlay = true
                    }
                },
                onReady: { color in
                    boardController.userColorName = color
                },
                boardThemeLight: Color(
                    red: themeAdapter.currentTheme.boardTheme.lightSquareColor.red,
                    green: themeAdapter.currentTheme.boardTheme.lightSquareColor.green,
                    blue: themeAdapter.currentTheme.boardTheme.lightSquareColor.blue,
                    opacity: themeAdapter.currentTheme.boardTheme.lightSquareColor.alpha
                ),
                boardThemeDark: Color(
                    red: themeAdapter.currentTheme.boardTheme.darkSquareColor.red,
                    green: themeAdapter.currentTheme.boardTheme.darkSquareColor.green,
                    blue: themeAdapter.currentTheme.boardTheme.darkSquareColor.blue,
                    opacity: themeAdapter.currentTheme.boardTheme.darkSquareColor.alpha
                ),
                pieceTheme: themeAdapter.currentTheme.pieceTheme,
                isHapticEnabled: composer.settingsVM.isHapticEnabled,
                isSoundEnabled: composer.settingsVM.isSoundEnabled
            )
            .equatable()
            //.padding(.horizontal, 16)
            .aspectRatio(1, contentMode: .fit)
            
            playerTurnInfo
                .padding(.top)
            
            Spacer(minLength: 8)
            
            let shouldHideHint = (examVM.remainingLives <= 1) && !hasUsedHintForCurrentPuzzle
            
            examControls
                .opacity(shouldHideHint ? 0 : 1)
                .disabled(shouldHideHint)
            
        }
        .onChange(of: examVM.currentIndex) { _, _ in
            showMoveOnOverlay = false
            hasUsedHintForCurrentPuzzle = false
        }
        .overlay {
            if showMoveOnOverlay {
                MoveOnOverlay { advanceAfterMistake() }
            }
        }
    }
    
    private var examHeader: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .foregroundColor(AppColors.textSecondary).padding(8)
            }
            .hoverEffect(.highlight)
            Spacer()
            Text("\(examVM.solvedCount + 1) / \(examVM.totalPuzzles)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < examVM.remainingLives ? "heart.fill" : "heart")
                        .foregroundColor(i < examVM.remainingLives
                                         ? AppColors.incorrect
                                         : AppColors.textSecondary.opacity(0.4))
                        .font(.system(size: 18))
                }
            }
            .padding(.trailing, 8)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }
    
    private var examControls: some View {
        HStack {
            Button {
                if !hasUsedHintForCurrentPuzzle {
                    examVM.handleHint()
                    hasUsedHintForCurrentPuzzle = true
                }
                
                boardController.showHint()
                if examVM.phase == .active && examVM.remainingLives > 0 {
                    showMoveOnOverlay = false
                }
            } label: {
                Label(hasUsedHintForCurrentPuzzle ? "Show Hint (Free)" : "Hint (−1 ♥)", systemImage: "lightbulb")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .hoverEffect(.highlight)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
    
    private var playerTurnInfo: some View {
        HStack {
            if !boardController.userColorName.isEmpty {
                let colorPrefix = boardController.userColorName == "White" ? "w" : "b"
                let pieceImageName = "\(themeAdapter.currentTheme.pieceTheme)_\(colorPrefix)k"
                
                HStack(spacing: 12) {
                    Image(pieceImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 42, height: 42)
                    
                    let key = "\(boardController.userColorName) to Move"
                    Text(LocalizedStringKey(key))
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
    
    private func advanceAfterMistake() {
        showMoveOnOverlay = false
        examVM.skipPuzzle()
    }
    
    // MARK: - Result Views
    
    private func resultView(passed: Bool) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Text(passed ? "🏆" : "💔").font(.system(size: 70))
            Text(passed ? "Exam Passed!" : "Exam Failed")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(passed ? AppColors.gold : AppColors.incorrect)
            Text(passed
                 ? "You've unlocked the next section."
                 : "You've run out of lives. Come back in 4 hours.")
            .font(.system(size: 15))
            .foregroundColor(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            Spacer()
            Button { dismiss() } label: {
                Text(passed ? "Continue" : "Back to Curriculum")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(passed ? AppColors.gold : AppColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .hoverEffect(.highlight)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

// MARK: - Move-On Overlay

private struct MoveOnOverlay: View {
    let onContinue: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("✗").font(.system(size: 48, weight: .bold)).foregroundColor(AppColors.incorrect)
                Text("Incorrect Move")
                    .font(.system(size: 20, weight: .semibold)).foregroundColor(AppColors.textPrimary)
                Text("The correct move has been highlighted.")
                    .font(.system(size: 14)).foregroundColor(AppColors.textSecondary)
                Button(action: onContinue) {
                    Text("Next Puzzle")
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.black)
                        .padding(.horizontal, 40).padding(.vertical, 14)
                        .background(AppColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .hoverEffect(.highlight)
                .keyboardShortcut(.defaultAction)
            }
            .padding(32)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 32)
        }
    }
}
