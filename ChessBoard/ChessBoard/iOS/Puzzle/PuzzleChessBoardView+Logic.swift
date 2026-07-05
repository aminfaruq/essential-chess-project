//
//  PuzzleChessBoardView+Logic.swift
//  NativeChessBoard
//
//  Created by Amin faruq on 08/06/26.
//

import UIKit

extension PuzzleChessBoardView {
    
    func routeUserMove(from sourceStr: String, to targetStr: String, promotionChar: String? = nil) {
        switch puzzleMode {
        case .standard:
            processUserMove(from: sourceStr, to: targetStr, promotionChar: promotionChar)
        case .learnThePieces:
            processUserMoveForLearnPieces(from: sourceStr, to: targetStr, promotionChar: promotionChar)
        }
    }
    
    func processUserMove(from sourceStr: String, to targetStr: String, promotionChar: String? = nil) {
        clearLegalMoveHints()
        guard let engine = engine, let validator = puzzleValidator else { return }
        
        if !engine.legalMoves(for: sourceStr).contains(targetStr) {
            selectedSquareString = nil
            HapticManager.shared.moveIllegal()
            SoundManager.shared.playError()
            animateSnapback { [weak self] in self?.clearHighlights() }
            return
        }
        
        self.isBoardLocked = true
        let promoSuffix = promotionChar ?? ""
        let moveStringUCI = "\(sourceStr)\(targetStr)\(promoSuffix)"
        let isCapture = engine.piece(at: targetStr) != nil
        
        let isValidByUCI = validator.validate(move: moveStringUCI)
        let isCheckmate = engine.wouldMoveResultInCheckmate(from: sourceStr, to: targetStr, promotion: promotionChar)
        
        if isValidByUCI || isCheckmate {
            clearSolutionArrow()
            
            // Identify if this is a castling move before executing it
            let isKingMove = engine.piece(at: sourceStr)?.kind == .king
            let castlingMoves = [
                "e1g1": ("h1", "f1"), "e1c1": ("a1", "d1"),
                "e8g8": ("h8", "f8"), "e8c8": ("a8", "d8")
            ]
            let rookMove = isKingMove ? castlingMoves["\(sourceStr)\(targetStr)"] : nil
            
            if engine.move(from: sourceStr, to: targetStr, promotion: promotionChar) {
                if isCapture {
                    HapticManager.shared.moveCapture()
                    SoundManager.shared.playCapture()
                } else {
                    SoundManager.shared.playMove()
                }
                
                selectedSquareString = nil
                clearHighlights()
                
                let finishUserMove = { [weak self] in
                    self?.cleanupGhost()
                    self?.renderPieces()
                    self?.highlightViews[sourceStr]?.isHidden = false
                    self?.highlightViews[targetStr]?.isHidden = false
                    
                    if validator.isCompleted || isCheckmate {
                        self?.isPuzzleCompleted = true
                        SoundManager.shared.playVictory()
                        self?.onPuzzleCompleted?()
                        return
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self?.makeOpponentMove()
                    }
                }
                
                if let rookMove = rookMove, let _ = squareViews[rookMove.0], let targetRookSquare = squareViews[rookMove.1], let rookView = pieceImageViews[rookMove.0] {
                    // Setup Rook Ghost
                    let rookGhost = UIImageView(image: rookView.image)
                    rookGhost.contentMode = .scaleAspectFit
                    rookGhost.frame = rookView.convert(rookView.bounds, to: overlayView)
                    overlayView.addSubview(rookGhost)
                    rookView.isHidden = true
                    
                    let rookTargetCenter = targetRookSquare.superview!.convert(targetRookSquare.center, to: overlayView)
                    
                    // Setup King Ghost ONLY if it's tap-to-move
                    var tempKingGhost: UIImageView?
                    var kingTargetCenter: CGPoint?
                    if self.ghostPieceView == nil, let sourceView = pieceImageViews[sourceStr], let targetSquare = squareViews[targetStr] {
                        let kg = UIImageView(image: sourceView.image)
                        kg.contentMode = .scaleAspectFit
                        kg.frame = sourceView.convert(sourceView.bounds, to: overlayView)
                        overlayView.addSubview(kg)
                        sourceView.isHidden = true
                        tempKingGhost = kg
                        kingTargetCenter = targetSquare.superview!.convert(targetSquare.center, to: overlayView)
                    }
                    
                    UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                        rookGhost.center = rookTargetCenter
                        if let kg = tempKingGhost, let ktc = kingTargetCenter {
                            kg.center = ktc
                        }
                    }) { _ in
                        rookGhost.removeFromSuperview()
                        tempKingGhost?.removeFromSuperview()
                        finishUserMove()
                    }
                } else {
                    finishUserMove()
                }
            }
        } else {
            HapticManager.shared.moveIllegal()
            SoundManager.shared.playError()
            drawNativeRedArrow(from: sourceStr, to: targetStr)
            selectedSquareString = nil
            animateSnapback { self.clearHighlights() }
            self.isBoardLocked = false
            onPuzzleWrong?()
        }
    }
    
    func processUserMoveForLearnPieces(from sourceStr: String, to targetStr: String, promotionChar: String? = nil) {
        clearLegalMoveHints()
        guard let engine = engine else { return }
        
        if !engine.legalMoves(for: sourceStr).contains(targetStr) {
            selectedSquareString = nil
            HapticManager.shared.moveIllegal()
            SoundManager.shared.playError()
            animateSnapback { [weak self] in self?.clearHighlights() }
            return
        }
        
        self.isBoardLocked = true
        let isCapture = engine.piece(at: targetStr) != nil
        
        if engine.move(from: sourceStr, to: targetStr, promotion: promotionChar) {
            if isCapture {
                HapticManager.shared.moveCapture()
                SoundManager.shared.playCapture()
            } else {
                SoundManager.shared.playMove()
            }
            
            selectedSquareString = nil
            clearHighlights()
            
            let finishUserMove = { [weak self] in
                self?.cleanupGhost()
                self?.renderPieces()
                self?.highlightViews[sourceStr]?.isHidden = false
                self?.highlightViews[targetStr]?.isHidden = false
                
                let opponentColor = self?.userColor == .white ? EngineColor.black : EngineColor.white
                var hasTargetsRemaining = false
                let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
                let ranks = ["1", "2", "3", "4", "5", "6", "7", "8"]
                
                for file in files {
                    for rank in ranks {
                        let square = file + rank
                        if let piece = self?.engine?.piece(at: square), piece.color == opponentColor {
                            hasTargetsRemaining = true
                            break
                        }
                    }
                    if hasTargetsRemaining { break }
                }
                
                if !hasTargetsRemaining {
                    self?.isPuzzleCompleted = true
                    SoundManager.shared.playVictory()
                    self?.onPuzzleCompleted?()
                } else {
                    // Force the turn back to the user's color so they can move again
                    if let uColor = self?.userColor {
                        self?.engine?.forceTurn(to: uColor)
                    }
                    
                    // Still targets left, user can make next move. Opponent doesn't move.
                    self?.isBoardLocked = false
                }
            }
            
            finishUserMove()
            
        } else {
            HapticManager.shared.moveIllegal()
            SoundManager.shared.playError()
            drawNativeRedArrow(from: sourceStr, to: targetStr)
            selectedSquareString = nil
            animateSnapback { self.clearHighlights() }
            self.isBoardLocked = false
        }
    }
    
    func makeOpponentMove() {
        guard let opMoveStringUCI = puzzleValidator?.consumeNextMove() else { return }
        
        self.isBoardLocked = true
        let sourceStr = String(opMoveStringUCI.prefix(2))
        let targetStr = String(opMoveStringUCI.dropFirst(2).prefix(2))
        let promoStr = opMoveStringUCI.count == 5 ? String(opMoveStringUCI.last!) : nil
        
        if let sourcePieceView = pieceImageViews[sourceStr], let targetSquareView = squareViews[targetStr] {
            
            // Check for castling
            let isKingMove = engine?.piece(at: sourceStr)?.kind == .king
            let castlingMoves = [
                "e1g1": ("h1", "f1"), "e1c1": ("a1", "d1"),
                "e8g8": ("h8", "f8"), "e8c8": ("a8", "d8")
            ]
            let rookMove = isKingMove ? castlingMoves["\(sourceStr)\(targetStr)"] : nil
            
            let ghost = UIImageView(image: sourcePieceView.image)
            ghost.contentMode = .scaleAspectFit
            ghost.frame = sourcePieceView.convert(sourcePieceView.bounds, to: overlayView)
            overlayView.addSubview(ghost)
            sourcePieceView.isHidden = true
            
            var rookGhost: UIImageView?
            if let rookMove = rookMove, let rookView = pieceImageViews[rookMove.0] {
                let rg = UIImageView(image: rookView.image)
                rg.contentMode = .scaleAspectFit
                rg.frame = rookView.convert(rookView.bounds, to: overlayView)
                overlayView.addSubview(rg)
                rookView.isHidden = true
                rookGhost = rg
            }
            
            let targetCenterInOverlay = targetSquareView.superview!.convert(targetSquareView.center, to: overlayView)
            let rookTargetCenter = rookMove != nil ? squareViews[rookMove!.1].map { $0.superview!.convert($0.center, to: overlayView) } : nil
            
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
                ghost.center = targetCenterInOverlay
                if let rg = rookGhost, let rtc = rookTargetCenter {
                    rg.center = rtc
                }
            }) { [weak self] _ in
                ghost.removeFromSuperview()
                rookGhost?.removeFromSuperview()
                let isCapture = self?.engine?.piece(at: targetStr) != nil
                _ = self?.engine?.move(from: sourceStr, to: targetStr, promotion: promoStr)
                if isCapture { SoundManager.shared.playCapture() } else { SoundManager.shared.playMove() }
                self?.clearHighlights()
                self?.renderPieces()
                self?.highlightViews[sourceStr]?.isHidden = false
                self?.highlightViews[targetStr]?.isHidden = false
                
                if self?.puzzleValidator?.isCompleted == true {
                    self?.isPuzzleCompleted = true
                    SoundManager.shared.playVictory()
                    self?.onPuzzleCompleted?()
                } else {
                    self?.isBoardLocked = false
                }
            }
        } else {
            let isCapture = self.engine?.piece(at: targetStr) != nil
            _ = self.engine?.move(from: sourceStr, to: targetStr, promotion: promoStr)
            if isCapture { SoundManager.shared.playCapture() } else { SoundManager.shared.playMove() }
            self.clearHighlights()
            self.renderPieces()
            self.isBoardLocked = false
        }
    }
}
