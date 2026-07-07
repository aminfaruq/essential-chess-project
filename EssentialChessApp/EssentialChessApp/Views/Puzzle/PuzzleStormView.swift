//
//  PuzzleStormView.swift
//  EssentialChessApp
//

import SwiftUI
import EssentialChess
import EssentialChessUI

public struct PuzzleStormView: View {
    @EnvironmentObject var composer: AppComposer
    @State private var viewModel: PuzzleStormViewModel?
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            if let vm = viewModel {
                PuzzleStormContainerView(vm: vm)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(AppColors.accent)
                    Text("Loading Storm...")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .navigationTitle("Puzzle Storm")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if viewModel == nil {
                composer.viewFactory.fetchPuzzleStormViewModel { fetchedVM in
                    self.viewModel = fetchedVM
                }
            }
        }
    }
}

// MARK: - Subviews

private struct PuzzleStormContainerView: View {
    @ObservedObject var vm: PuzzleStormViewModel
    @EnvironmentObject var container: DependencyContainer
    
    var body: some View {
        PuzzleStormActiveView(vm: vm)
    }
}

private struct PuzzleStormActiveView: View {
    @ObservedObject var vm: PuzzleStormViewModel
    @EnvironmentObject var themeAdapter: ThemeAdapter
    @EnvironmentObject var composer: AppComposer
    @StateObject private var boardController = ChessBoardController()
    
    var body: some View {
        ZStack {
            if !vm.isGameActive && !vm.isGameOver {
                // Intro Screen
                introScreen
            } else if let puzzle = vm.currentPuzzle {
                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 8)
                    boardArea(puzzle: puzzle)
                    playerTurnInfo
                        .padding(.top)
                    Spacer(minLength: 8)
                    controls
                }
            } else if vm.isGameOver {
                // Overlay handles this, but keep background clean
                Color.clear
            } else {
                Text("Loading puzzles...")
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Penalty Flash
            if vm.showPenaltyIndicator {
                Color.red.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                vm.showPenaltyIndicator = false
                            }
                        }
                    }
            }
            
            // Bonus Flash
            if vm.showBonusIndicator {
                VStack {
                    Text("+\(vm.lastBonusAmount)s")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.green)
                        .shadow(color: .black, radius: 2)
                        .scaleEffect(1.5)
                        .transition(.scale.combined(with: .opacity))
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            vm.showBonusIndicator = false
                        }
                    }
                }
            }
            
            if vm.isGameOver {
                Color.black.opacity(0.6).ignoresSafeArea()
                    .transition(.opacity)
                
                PuzzleStormResultOverlay(vm: vm)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(), value: vm.isGameOver)
    }
    
    private var introScreen: some View {
        VStack(spacing: 32) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            VStack(spacing: 8) {
                Text("Puzzle Storm")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text("Solve as many as you can in 3 minutes")
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Button {
                vm.onStartTapped()
            } label: {
                Text("Start Storm")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
                    .background(AppColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    private var header: some View {
        HStack {
            // Score
            VStack(alignment: .leading, spacing: 2) {
                Text("Score")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                Text("\(vm.currentScore)")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
            
            // Timer
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .foregroundColor(vm.timeRemaining < 30 ? .red : .yellow)
                Text(timeString(from: vm.timeRemaining))
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(vm.timeRemaining < 30 ? .red : AppColors.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppColors.surface)
            .cornerRadius(12)
            
            Spacer()
            
            // Combo
            VStack(alignment: .trailing, spacing: 2) {
                Text("Combo")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                Text("\(vm.currentCombo)")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(height: 50)
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
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
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
        .frame(height: 80)
    }
}

private struct PuzzleStormResultOverlay: View {
    @ObservedObject var vm: PuzzleStormViewModel
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Time's Up!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.incorrect)
            
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
                Image(systemName: "bolt.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.yellow)
            }
            
            HStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Score")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    Text("\(vm.currentScore)")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(AppColors.textPrimary)
                }
                
                VStack(spacing: 8) {
                    Text("Best Combo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    Text("\(vm.highestCombo)")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                }
            }
            .padding(.vertical, 16)
            
            Button {
                vm.onStartTapped()
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
