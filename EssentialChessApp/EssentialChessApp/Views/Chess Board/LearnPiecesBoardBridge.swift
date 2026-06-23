//
//  LearnPiecesBoardBridge.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 23/06/26.
//

import SwiftUI
import UIKit
import Combine
import EssentialChess
import NativeChessBoard

public struct LearnPiecesBoardBridge: UIViewRepresentable, Equatable {
    public let puzzle: Puzzle
    public let controller: ChessBoardController
    public var onCompleted: () -> Void
    public var onWrong: () -> Void
    public var onReady: (String) -> Void
    
    public var boardThemeLight: Color
    public var boardThemeDark: Color
    public var pieceTheme: String
    public var isHapticEnabled: Bool
    public var isSoundEnabled: Bool
    
    public init(
        puzzle: Puzzle,
        controller: ChessBoardController,
        onCompleted: @escaping () -> Void,
        onWrong: @escaping () -> Void,
        onReady: @escaping (String) -> Void,
        boardThemeLight: Color = AppColors.boardLight,
        boardThemeDark: Color = AppColors.boardDark,
        pieceTheme: String = "default",
        isHapticEnabled: Bool = true,
        isSoundEnabled: Bool = true
    ) {
        self.puzzle = puzzle
        self.controller = controller
        self.onCompleted = onCompleted
        self.onWrong = onWrong
        self.onReady = onReady
        self.boardThemeLight = boardThemeLight
        self.boardThemeDark = boardThemeDark
        self.pieceTheme = pieceTheme
        self.isHapticEnabled = isHapticEnabled
        self.isSoundEnabled = isSoundEnabled
    }
    
    public func makeCoordinator() -> Coordinator { Coordinator() }
    
    public func makeUIView(context: Context) -> NativeChessBoardView {
        let view = NativeChessBoardView()
        applyTheme(to: view)
        controller.boardView = view
        
        view.onPuzzleCompleted = onCompleted
        view.onPuzzleWrong = onWrong
        view.onPuzzleReady = { colorName in
            DispatchQueue.main.async {
                self.onReady(colorName)
            }
        }
        
        context.coordinator.lastPuzzleId = puzzle.id
        
        view.startLearnThePiecesPuzzle(fen: puzzle.fen)
        
        return view
    }
    
    public func updateUIView(_ uiView: NativeChessBoardView, context: Context) {
        controller.boardView = uiView
        uiView.onPuzzleCompleted = onCompleted
        uiView.onPuzzleWrong = onWrong
        uiView.onPuzzleReady = { colorName in
            DispatchQueue.main.async {
                self.onReady(colorName)
            }
        }
        
        applyTheme(to: uiView)
        
        if context.coordinator.lastPuzzleId != puzzle.id {
            context.coordinator.lastPuzzleId = puzzle.id
            
            uiView.startLearnThePiecesPuzzle(fen: puzzle.fen)
        }
    }
    
    public class Coordinator {
        var lastPuzzleId: String?
    }
    
    private func applyTheme(to view: NativeChessBoardView) {
        view.setBoardTheme(light: UIColor(boardThemeLight), dark: UIColor(boardThemeDark))
        view.setHighlightColor(UIColor(AppColors.hint), alpha: 0.45)
        view.setPieceTheme(pieceTheme)
        view.setHapticEnabled(isHapticEnabled)
        view.setSoundEnabled(isSoundEnabled)
    }
    
    public static func == (lhs: LearnPiecesBoardBridge, rhs: LearnPiecesBoardBridge) -> Bool {
        return lhs.puzzle.id == rhs.puzzle.id &&
               lhs.boardThemeLight == rhs.boardThemeLight &&
               lhs.boardThemeDark == rhs.boardThemeDark &&
               lhs.pieceTheme == rhs.pieceTheme &&
               lhs.isHapticEnabled == rhs.isHapticEnabled &&
               lhs.isSoundEnabled == rhs.isSoundEnabled
    }
}
