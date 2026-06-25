//
//  AnalysisChessBoardBridge.swift
//  EssentialChessApp
//

import SwiftUI
import UIKit
import Combine
import ChessBoard
import EssentialChessUI

public class AnalysisChessBoardController: ObservableObject {
    public internal(set) weak var boardView: AnalysisChessBoardView?
    
    public init() {}
    
    public func playMove(source: String, target: String, promotion: String?, completion: @escaping (String) -> Void) {
        boardView?.playMove(from: source, to: target, promotion: promotion) { [weak self] in
            let fen = self?.boardView?.currentFen ?? ""
            completion(fen)
        }
    }
    
    public func setPosition(fen: String, orientation: String) {
        let engineColor: EngineColor = orientation.lowercased() == "black" ? .black : .white
        boardView?.setPosition(fen: fen, orientation: engineColor)
    }
    
    public func drawArrow(source: String, target: String, colorHex: String) {
        let uiColor: UIColor
        if colorHex.lowercased() == "#ff0000" {
            uiColor = .systemRed
        } else {
            uiColor = .systemBlue
        }
        boardView?.drawArrow(from: source, to: target, color: uiColor, isPersistent: true)
    }
    
    public func clearArrows() {
        boardView?.clearSolutionArrow()
    }
    
    public func undoLastMove() {
        boardView?.undoLastMove()
    }
}

public struct AnalysisChessBoardBridge: UIViewRepresentable, Equatable {
    public let fen: String
    public let orientation: String // "White" or "Black"
    public let controller: AnalysisChessBoardController
    public var onUserMoved: (_ uci: String, _ resultingFen: String) -> Void
    
    public var boardThemeLight: Color
    public var boardThemeDark: Color
    public var pieceTheme: String
    public var isHapticEnabled: Bool
    public var isSoundEnabled: Bool
    
    public init(
        fen: String,
        orientation: String,
        controller: AnalysisChessBoardController,
        onUserMoved: @escaping (_ uci: String, _ resultingFen: String) -> Void,
        boardThemeLight: Color = AppColors.boardLight,
        boardThemeDark: Color = AppColors.boardDark,
        pieceTheme: String = "default",
        isHapticEnabled: Bool = true,
        isSoundEnabled: Bool = true
    ) {
        self.fen = fen
        self.orientation = orientation
        self.controller = controller
        self.onUserMoved = onUserMoved
        self.boardThemeLight = boardThemeLight
        self.boardThemeDark = boardThemeDark
        self.pieceTheme = pieceTheme
        self.isHapticEnabled = isHapticEnabled
        self.isSoundEnabled = isSoundEnabled
    }
    
    public func makeUIView(context: Context) -> AnalysisChessBoardView {
        let view = AnalysisChessBoardView()
        applyTheme(to: view)
        controller.boardView = view
        
        view.onUserMoved = { [weak view] uci in
            let resultingFen = view?.currentFen ?? ""
            self.onUserMoved(uci, resultingFen)
        }
        
        let engineColor: EngineColor = orientation.lowercased() == "black" ? .black : .white
        view.setPosition(fen: fen, orientation: engineColor)
        
        return view
    }
    
    public func updateUIView(_ uiView: AnalysisChessBoardView, context: Context) {
        controller.boardView = uiView
        uiView.onUserMoved = { [weak uiView] uci in
            let resultingFen = uiView?.currentFen ?? ""
            self.onUserMoved(uci, resultingFen)
        }
        
        // Removed applyTheme(to: uiView) from here. 
        // Calling it causes setBoardTheme to destroy and rebuild all 64 square views, 
        // which interrupts gestures and animations every time currentFen changes.
        
        // We do not force setPosition on every SwiftUI state change, 
        // to avoid snapping back pieces while the user interacts or during computer moves.
        // FEN synchronization is handled via `controller.playMove` and `controller.undoLastMove`.
    }
    
    private func applyTheme(to view: AnalysisChessBoardView) {
        view.setBoardTheme(light: UIColor(boardThemeLight), dark: UIColor(boardThemeDark))
        view.setHighlightColor(UIColor(AppColors.hint), alpha: 0.45)
        view.setPieceTheme(pieceTheme)
        view.setHapticEnabled(isHapticEnabled)
        view.setSoundEnabled(isSoundEnabled)
    }
    
    public static func == (lhs: AnalysisChessBoardBridge, rhs: AnalysisChessBoardBridge) -> Bool {
        return lhs.fen == rhs.fen &&
               lhs.orientation == rhs.orientation &&
               lhs.boardThemeLight == rhs.boardThemeLight &&
               lhs.boardThemeDark == rhs.boardThemeDark &&
               lhs.pieceTheme == rhs.pieceTheme &&
               lhs.isHapticEnabled == rhs.isHapticEnabled &&
               lhs.isSoundEnabled == rhs.isSoundEnabled
    }
}
