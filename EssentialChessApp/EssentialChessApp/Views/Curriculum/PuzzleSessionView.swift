//
//  PuzzleSessionView.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//

import SwiftUI
import EssentialChess
import EssentialChessUI

public struct PuzzleSessionView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var boardVM: PuzzleBoardViewModel
    @StateObject private var boardController = ChessBoardController()
    @State private var showSequenceList = false
    
    let categoryTitle: String
    let onSessionClosed: () -> Void
    
    public init(
        categoryTitle: String,
        boardVM: PuzzleBoardViewModel,
        onSessionClosed: @escaping () -> Void
    ) {
        self.categoryTitle = categoryTitle
        self._boardVM = StateObject(wrappedValue: boardVM)
        self.onSessionClosed = onSessionClosed
    }
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            if boardVM.isSessionComplete {
                sessionCompletedView
            } else if let puzzle = boardVM.currentPuzzle {
                VStack(spacing: 0) {
                    puzzleProgress
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
        .navigationTitle(categoryTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(boardVM.isSessionComplete)
        .sheet(isPresented: $showSequenceList) {
            SequenceListView(vm: boardVM, isPresented: $showSequenceList)
        }
    }
    
    // MARK: - Subviews
    
    private var puzzleProgress: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Puzzle \(boardVM.currentActiveIndex + 1) of \(boardVM.puzzles.count)")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                if let puzzle = boardVM.currentPuzzle {
                    Label("\(puzzle.rating)", systemImage: "star")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.gold.opacity(0.8))
                }
            }
            ProgressBarView(progress: boardVM.puzzles.isEmpty ? 0 : Double(boardVM.currentActiveIndex) / Double(boardVM.puzzles.count))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    private func boardArea(puzzle: Puzzle) -> some View {
        ChessBoardBridge(
            puzzle: puzzle,
            controller: boardController,
            onCompleted: {
                boardVM.markSolved()
            },
            onWrong: {
                boardVM.markWrong()
            },
            onReady: { color in
                boardController.userColorName = color
            }
        )
        .padding(.horizontal, 16)
        .aspectRatio(1, contentMode: .fit)
    }
    
    private var controls: some View {
        HStack(spacing: 12) {
            Button { boardController.showHint() } label: {
                Label("Hint", systemImage: "lightbulb")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Button { showSequenceList = true } label: {
                Label("Puzzles", systemImage: "list.number")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Spacer()
            
            if boardVM.isSolved {
                Button { boardVM.triggerNext() } label: {
                    Label("Next", systemImage: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
        
    }
    
    private var playerTurnInfo: some View {
        HStack {
            if !boardController.userColorName.isEmpty {
                let colorPrefix = boardController.userColorName == "White" ? "w" : "b"
                let pieceImageName = "default_\(colorPrefix)k"
                
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
    }
    
    
    private var sessionCompletedView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("✓")
                .font(.system(size: 64, weight: .bold))
                .foregroundColor(AppColors.accent)
            Text("Theme Complete!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            Text(categoryTitle)
                .font(.system(size: 16))
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Button { dismiss() } label: {
                Text("Back to Themes")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}
