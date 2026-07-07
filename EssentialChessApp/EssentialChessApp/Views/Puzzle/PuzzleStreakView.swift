//
//  PuzzleStreakView.swift
//  EssentialChessApp
//

import SwiftUI
import UIKit
import EssentialChess
import EssentialChessUI

public struct PuzzleStreakView: View {
    @EnvironmentObject var composer: AppComposer
    @State private var viewModel: PuzzleStreakViewModel?
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            if let vm = viewModel {
                PuzzleStreakContainerView(vm: vm)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(AppColors.accent)
                    Text("Loading Streak...")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .navigationTitle("Puzzle Streak")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if viewModel == nil {
                composer.viewFactory.fetchPuzzleStreakViewModel { fetchedVM in
                    self.viewModel = fetchedVM
                }
            }
        }
    }
}

// MARK: - Subviews

private struct PuzzleStreakContainerView: View {
    @ObservedObject var vm: PuzzleStreakViewModel
    @EnvironmentObject var container: DependencyContainer
    
    var body: some View {
        PuzzleStreakActiveView(vm: vm)
    }
}

private struct PuzzleStreakActiveView: View {
    @ObservedObject var vm: PuzzleStreakViewModel
    @EnvironmentObject var themeAdapter: ThemeAdapter
    @EnvironmentObject var composer: AppComposer
    @StateObject private var boardController = ChessBoardController()
    
    var body: some View {
        ZStack {
            if let puzzle = vm.currentPuzzle {
                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 8)
                    
                    boardArea(puzzle: puzzle)
                    
                    playerTurnInfo
                        .padding(.top)
                        
                    Spacer(minLength: 8)
                    
                    controls
                }
            } else {
                Text("No puzzles available.")
                    .foregroundColor(AppColors.textSecondary)
            }
            
            if vm.showResultOverlay {
                Color.black.opacity(0.6).ignoresSafeArea()
                    .transition(.opacity)
                
                PuzzleStreakResultOverlay(vm: vm)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(), value: vm.showResultOverlay)
    }
    
    private var header: some View {
        HStack {
            if vm.isPuzzleFinished {
                Text("Streak Ended!")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.incorrect)
            } else {
                Text("Find the best move")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer(minLength: 8)
            
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(vm.currentStreak)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColors.surface)
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(height: 44)
    }
    
    private func boardArea(puzzle: Puzzle) -> some View {
        PuzzleBoardBridge(
            puzzle: puzzle,
            controller: boardController,
            onCompleted: {
                vm.handlePuzzleCompletion(isCorrect: true)
            },
            onWrong: {
                vm.handlePuzzleCompletion(isCorrect: false)
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
        .aspectRatio(1, contentMode: .fit)
        .onChange(of: vm.showCorrectMove) { _, newValue in
            if newValue {
                // When failed, optionally show the solution immediately
                boardController.showSolution()
            }
        }
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
        .frame(height: 50)
    }
    
    private var controls: some View {
        HStack {
            Spacer()
            
            if vm.isPuzzleFinished {
                Button {
                    vm.onNextTapped()
                } label: {
                    Label("Play Again", systemImage: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .hoverEffect(.highlight)
                .keyboardShortcut(.defaultAction)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
        .frame(height: 80)
    }
}

private struct PuzzleStreakResultOverlay: View {
    @ObservedObject var vm: PuzzleStreakViewModel
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Streak Ended")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            if vm.isNewRecord {
                VStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.gold)
                        .scaleEffect(animateIcon ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                            value: animateIcon
                        )
                    
                    Text("New Record!")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.gold)
                }
                .onAppear {
                    animateIcon = true
                }
            } else {
                Image(systemName: "flame.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
            }
            
            HStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Score")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    Text("\(vm.currentStreak)")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(AppColors.textPrimary)
                }
                
                if !vm.isNewRecord {
                    VStack(spacing: 8) {
                        Text("Best")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                        Text("\(vm.currentHighestStreak)")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(.vertical, 16)
            
            Button {
                vm.onNextTapped()
            } label: {
                Text("Play Again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(32)
        .background(AppColors.surface)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 40)
    }
}
