//
//  PlacementTestView.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//

import SwiftUI
import EssentialChess
import EssentialChessUI

public struct PlacementTestView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var themeAdapter: ThemeAdapter
    @EnvironmentObject var composer: AppComposer

    @StateObject private var boardController = ChessBoardController()
    
    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            if viewModel.isComplete {
                completionView
            } else if let puzzle = viewModel.currentPuzzle {
                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 12)
                    ProgressBarView(progress: viewModel.progress)
                        .padding(.horizontal, 24)
                    Spacer(minLength: 12)
                    
                    ChessBoardBridge(
                        puzzle: puzzle,
                        controller: boardController,
                        onCompleted: {
                            viewModel.handleResult(isCorrect: true)
                        },
                        onWrong: {
                            viewModel.handleResult(isCorrect: false)
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
                    
                    Spacer(minLength: 12)
                    statusBar
                    playerTurnInfo
                }
            } else {
                VStack(spacing: 16) {
                    ProgressView().tint(AppColors.accent)
                    Text("Preparing your diagnostic test...")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .foregroundColor(AppColors.textSecondary)
                    .padding(8)
            }
            .hoverEffect(.highlight)
            Spacer()
            VStack(spacing: 2) {
                Text("Placement Test")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text("Puzzle \(viewModel.currentPuzzleIndex + 1) of \(viewModel.totalPuzzles)")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
            Text("~\(Int(viewModel.currentRating))")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(AppColors.gold)
                .padding(8)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }
    
    private var statusBar: some View {
        Text("Find the best move")
            .font(.system(size: 14))
            .foregroundColor(AppColors.textSecondary)
            .frame(height: 44)
            .padding(.bottom, 24)
    }
    
    private var playerTurnInfo: some View {
        HStack {
            if !boardController.userColorName.isEmpty {
                let colorPrefix = boardController.userColorName == "White" ? "w" : "b"
                let pieceImageName = "\(themeAdapter.currentTheme.pieceTheme)_\(colorPrefix)k"
                
                HStack(spacing: 12) {
                    let key = "\(boardController.userColorName) to Move"
                    Text(LocalizedStringKey(key))
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Image(pieceImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 42, height: 42)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
    
    private var completionView: some View {
        VStack(spacing: 28) {
            Spacer()
            Text("🏆").font(.system(size: 60))
            Text("Assessment Complete")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 8) {
                Text("Your estimated rating")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                Text("\(Int(viewModel.currentRating))")
                    .font(.system(size: 48, weight: .black, design: .monospaced))
                    .foregroundColor(AppColors.gold)
            }
            Spacer()
            
            Button {
                viewModel.commitResults()
            } label: {
                Text("Start Learning")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .hoverEffect(.highlight)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

