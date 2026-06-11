//
//  ChessBoardBridge.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//

import SwiftUI
import UIKit
import Combine
import EssentialChess
import NativeChessBoard

public class ChessBoardController: ObservableObject {
    fileprivate(set) weak var boardView: NativeChessBoardView?
    
    @Published public var userColorName: String = ""
    
    public init() {}
    
    public func showHint() {
        boardView?.showHint()
    }
}

// MARK: - UIViewRepresentable Bridge

public struct ChessBoardBridge: UIViewRepresentable {
    public let puzzle: Puzzle
    public let controller: ChessBoardController
    public var onCompleted: () -> Void
    public var onWrong: () -> Void
    public var onReady: (String) -> Void
    
    public var boardThemeLight: Color
    public var boardThemeDark: Color
    public var pieceTheme: String
    
    public init(
        puzzle: Puzzle,
        controller: ChessBoardController,
        onCompleted: @escaping () -> Void,
        onWrong: @escaping () -> Void,
        onReady: @escaping (String) -> Void,
        boardThemeLight: Color = AppColors.boardLight,
        boardThemeDark: Color = AppColors.boardDark,
        pieceTheme: String = "default"
    ) {
        self.puzzle = puzzle
        self.controller = controller
        self.onCompleted = onCompleted
        self.onWrong = onWrong
        self.onReady = onReady
        self.boardThemeLight = boardThemeLight
        self.boardThemeDark = boardThemeDark
        self.pieceTheme = pieceTheme
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
        view.startPuzzle(fen: puzzle.fen, moves: puzzle.moves)
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
            uiView.startPuzzle(fen: puzzle.fen, moves: puzzle.moves)
        }
    }
    
    public class Coordinator {
        var lastPuzzleId: String?
    }
    
    private func applyTheme(to view: NativeChessBoardView) {
        view.setBoardTheme(light: UIColor(boardThemeLight), dark: UIColor(boardThemeDark))
        view.setHighlightColor(UIColor(AppColors.hint), alpha: 0.45)
        view.setPieceTheme(pieceTheme)
    }
}
