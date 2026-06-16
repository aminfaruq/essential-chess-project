//
//  PuzzleMixView.swift
//  EssentialChessApp
//
//  Created by App on 11/06/26.
//

import SwiftUI
import EssentialChess
import EssentialChessUI

public struct PuzzleMixView: View {
    @EnvironmentObject var composer: AppComposer
    @State private var viewModel: PuzzleMixViewModel?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if let vm = viewModel {
                    PuzzleMixContainerView(vm: vm)
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(AppColors.accent)
                        Text("Loading Puzzles...")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .navigationTitle("Puzzle Mix")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            if viewModel == nil {
                composer.viewFactory.fetchPuzzleMixViewModel { fetchedVM in
                    self.viewModel = fetchedVM
                }
            }
        }
    }
}

// MARK: - Subviews

private struct PuzzleMixContainerView: View {
    @ObservedObject var vm: PuzzleMixViewModel
    @EnvironmentObject var container: DependencyContainer
    
    var body: some View {
        Group {
            if vm.isDailyLimitReached {
                VStack(spacing: 20) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.locked)
                    Text("Daily Limit Reached")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Text("You've completed your 7 free puzzles today. Come back tomorrow or upgrade to Pro to play endlessly.")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Button {
                        vm.showPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text("Unlock Pro")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(AppColors.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 8)
                }
            } else {
                PuzzleMixActiveView(vm: vm)
            }
        }
        .sheet(isPresented: $vm.showPaywall) {
            PaywallView()
        }
        .onReceive(container.progressAdapter.publisher()) { progress in
            if progress.isPro && vm.isDailyLimitReached {
                vm.resumeAfterPurchase()
            }
        }
    }
}

private struct PuzzleMixActiveView: View {
    @ObservedObject var vm: PuzzleMixViewModel
    @EnvironmentObject var themeAdapter: ThemeAdapter
    @StateObject private var boardController = ChessBoardController()
    
    var body: some View {
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
    }
    
    private var headerText: String {
        if vm.isPuzzleFinished {
            if vm.showCorrectMove || vm.hasUsedHint {
                return "Get it right next time!"
            } else {
                return "Excellent Move!"
            }
        }
        return "Find the best move"
    }
    
    private var headerColor: Color {
        if vm.isPuzzleFinished {
            if vm.showCorrectMove || vm.hasUsedHint {
                return AppColors.incorrect
            } else {
                return AppColors.correct
            }
        }
        return AppColors.textPrimary
    }
    
    private var header: some View {
        HStack {
            Text(headerText)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(headerColor)
                .animation(.easeInOut(duration: 0.3), value: headerText)
            Spacer()
            if vm.isPuzzleFinished, let change = vm.ratingChange {
                let oldRating = vm.actualRating - change
                let isPositive = change >= 0
                let changeInt = Int(change)
                
                HStack(spacing: 4) {
                    Text("~\(Int(oldRating))")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(AppColors.gold)
                    
                    Text(isPositive ? "+\(changeInt)" : "\(changeInt)")
                        .font(.system(size: 11, weight: .light, design: .monospaced))
                        .foregroundColor(isPositive ? AppColors.correct : AppColors.incorrect)
                }
                .padding(8)
            } else {
                Text("~\(Int(vm.actualRating))")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(AppColors.gold)
                    .padding(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private func boardArea(puzzle: Puzzle) -> some View {
        ChessBoardBridge(
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
            pieceTheme: themeAdapter.currentTheme.pieceTheme
        )
        .padding(.horizontal, 16)
        .aspectRatio(1, contentMode: .fit)
        //        .onChange(of: vm.showCorrectMove) { _, newValue in
        //            if newValue {
        //                boardController.showHint()
        //            }
        //        }
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
                    
                    Text("\(boardController.userColorName) to Move")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                vm.handleHint()
                boardController.showHint()
            } label: {
                Label("Hint", systemImage: "lightbulb")
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .hoverEffect(.highlight)
            
            
            Spacer()
            
            if vm.isPuzzleFinished {
                Button {
                    vm.onNextTapped()
                } label: {
                    Label("Next", systemImage: "arrow.right")
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
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
}
