import UIKit

extension AnalysisChessBoardView {
    
    func processUserMove(from sourceStr: String, to targetStr: String, promotionChar: String? = nil) {
        guard let engine = engine else {
            animateSnapback()
            return
        }
        
        let legalMoves = engine.legalMoves(for: sourceStr)
        if !legalMoves.contains(targetStr) {
            animateSnapback { self.clearHighlights() }
            return
        }
        
        let isCapture = engine.piece(at: targetStr) != nil
        let isEnPassant = engine.isEnPassantCapture(from: sourceStr, to: targetStr)
        
        // Detect castling before executing the move
        let isKingMove = engine.piece(at: sourceStr)?.kind == .king
        let castlingMoves: [String: (rookFrom: String, rookTo: String)] = [
            "e1g1": ("h1", "f1"), "e1c1": ("a1", "d1"),
            "e8g8": ("h8", "f8"), "e8c8": ("a8", "d8")
        ]
        let rookMove = isKingMove ? castlingMoves["\(sourceStr)\(targetStr)"] : nil
        
        if engine.move(from: sourceStr, to: targetStr, promotion: promotionChar) {
            // Play appropriate sound based on move type
            playSoundForMove(isCapture: isCapture || isEnPassant, gameState: engine.gameState)
            
            clearLegalMoveHints()
            clearHighlights()
            highlightViews[sourceStr]?.isHidden = false
            highlightViews[targetStr]?.isHidden = false
            
            selectedSquareString = nil
            
            let capturedSquareStr = isEnPassant ? "\(targetStr.first!)\(sourceStr.last!)" : targetStr
            let pieceToHide = (isCapture || isEnPassant) ? pieceImageViews[capturedSquareStr] : nil
            
            let finishMove = { [weak self] in
                pieceToHide?.alpha = 1.0
                self?.cleanupGhost()
                self?.renderPieces()
                
                let uci = "\(sourceStr)\(targetStr)\(promotionChar ?? "")"
                self?.onUserMoved?(uci)
                self?.notifyGameStateIfNeeded()
                self?.broadcastState()
            }
            
            if let rookMove = rookMove {
                animateCastling(
                    kingSource: sourceStr, kingTarget: targetStr,
                    rookSource: rookMove.rookFrom, rookTarget: rookMove.rookTo,
                    completion: finishMove
                )
            } else if let ghost = ghostPieceView, let targetView = squareViews[targetStr] {
                // Drag-based move: animate ghost piece to target
                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: {
                    ghost.center = self.overlayView.convert(targetView.center, from: targetView.superview)
                    pieceToHide?.alpha = 0.0
                }) { _ in
                    finishMove()
                }
            } else if let originalPieceView = pieceImageViews[sourceStr], let targetView = squareViews[targetStr] {
                // Tap-based move: animate ghost piece from source to target
                let ghost = UIImageView(image: originalPieceView.image)
                ghost.contentMode = .scaleAspectFit
                ghost.frame = originalPieceView.convert(originalPieceView.bounds, to: overlayView)
                overlayView.addSubview(ghost)
                originalPieceView.isHidden = true
                
                UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                    ghost.center = self.overlayView.convert(targetView.center, from: targetView.superview)
                    pieceToHide?.alpha = 0.0
                }) { _ in
                    ghost.removeFromSuperview()
                    finishMove()
                }
            } else {
                // Fallback instant render
                finishMove()
            }
            
        } else {
            animateSnapback { self.clearHighlights() }
        }
    }
    
    public func playMove(from sourceStr: String, to targetStr: String, promotion promoStr: String? = nil, completion: (() -> Void)? = nil) {
        guard let engine = engine else {
            completion?()
            return
        }
        
        // Force layout so newly rendered pieces from renderPieces() have valid frames before animation
        boardContainer.layoutIfNeeded()
        
        let isCapture = engine.piece(at: targetStr) != nil
        let isEnPassant = engine.isEnPassantCapture(from: sourceStr, to: targetStr)
        
        // Detect castling before executing the move
        let isKingMove = engine.piece(at: sourceStr)?.kind == .king
        let castlingMoves: [String: (rookFrom: String, rookTo: String)] = [
            "e1g1": ("h1", "f1"), "e1c1": ("a1", "d1"),
            "e8g8": ("h8", "f8"), "e8c8": ("a8", "d8")
        ]
        let rookMove = isKingMove ? castlingMoves["\(sourceStr)\(targetStr)"] : nil
        
        if engine.move(from: sourceStr, to: targetStr, promotion: promoStr) {
            guard let _ = squareViews[sourceStr],
                  let tgtView = squareViews[targetStr],
                  let originalPieceView = pieceImageViews[sourceStr] else {
                playSoundForMove(isCapture: isCapture || isEnPassant, gameState: engine.gameState)
                renderPieces()
                notifyGameStateIfNeeded()
                completion?()
                return
            }
            
            // If the view hasn't been fully laid out or isn't on screen yet, don't attempt to animate pieces from (0,0)
            if self.window == nil || originalPieceView.bounds.width == 0 {
                playSoundForMove(isCapture: isCapture || isEnPassant, gameState: engine.gameState)
                renderPieces()
                notifyGameStateIfNeeded()
                completion?()
                return
            }
            
            let ghost = UIImageView(image: originalPieceView.image)
            ghost.contentMode = .scaleAspectFit
            ghost.frame = originalPieceView.convert(originalPieceView.bounds, to: overlayView)
            overlayView.addSubview(ghost)
            
            originalPieceView.isHidden = true
            // Captured piece is intentionally kept visible during animation for a natural slide-over effect.
            
            clearLegalMoveHints()
            clearHighlights()
            highlightViews[sourceStr]?.isHidden = false
            
            // Setup rook ghost for castling
            var rookGhost: UIImageView?
            var rookTargetCenter: CGPoint?
            if let rookMove = rookMove, let rookView = pieceImageViews[rookMove.rookFrom],
               let rookTargetSquare = squareViews[rookMove.rookTo] {
                let rg = UIImageView(image: rookView.image)
                rg.contentMode = .scaleAspectFit
                rg.frame = rookView.convert(rookView.bounds, to: overlayView)
                overlayView.addSubview(rg)
                rookView.isHidden = true
                rookGhost = rg
                rookTargetCenter = rookTargetSquare.superview!.convert(rookTargetSquare.center, to: overlayView)
            }
            
            let capturedSquareStr = isEnPassant ? "\(targetStr.first!)\(sourceStr.last!)" : targetStr
            let pieceToHide = (isCapture || isEnPassant) ? pieceImageViews[capturedSquareStr] : nil
            
            let targetCenter = overlayView.convert(tgtView.center, from: tgtView.superview)
            
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                ghost.center = targetCenter
                pieceToHide?.alpha = 0.0
                if let rg = rookGhost, let rtc = rookTargetCenter {
                    rg.center = rtc
                }
            }) { [weak self] _ in
                pieceToHide?.alpha = 1.0
                self?.playSoundForMove(isCapture: isCapture || isEnPassant, gameState: engine.gameState)
                self?.highlightViews[targetStr]?.isHidden = false
                self?.renderPieces()
                ghost.removeFromSuperview()
                rookGhost?.removeFromSuperview()
                self?.notifyGameStateIfNeeded()
                completion?()
            }
        } else {
            completion?()
        }
    }
    
    // MARK: - Private Helpers
    
    /// Plays the appropriate sound effect based on the move type and resulting game state.
    private func playSoundForMove(isCapture: Bool, gameState: EngineGameState) {
        switch gameState {
        case .checkmate:
            feedback.playVictory()
        case .check:
            feedback.playCheck()
        case .stalemate:
            feedback.playMove()
        case .inProgress:
            if isCapture {
                feedback.moveCapture()
            } else {
                feedback.playMove()
            }
        }
    }
    
    /// Notifies the consumer about game state changes (check, checkmate, stalemate).
    private func notifyGameStateIfNeeded() {
        guard let engine = engine else { return }
        switch engine.gameState {
        case .checkmate(let color):
            let winner = color == .white ? "black" : "white"
            onGameStateChanged?("checkmate_\(winner)")
        case .stalemate:
            onGameStateChanged?("stalemate")
        case .check:
            onGameStateChanged?("check")
        case .inProgress:
            break
        }
    }
    
    /// Animates the castling move with both king and rook moving simultaneously.
    private func animateCastling(
        kingSource: String, kingTarget: String,
        rookSource: String, rookTarget: String,
        completion: @escaping () -> Void
    ) {
        if let rookView = pieceImageViews[rookSource],
           let rookTargetSquare = squareViews[rookTarget] {
            let rg = UIImageView(image: rookView.image)
            rg.contentMode = .scaleAspectFit
            rg.frame = rookView.convert(rookView.bounds, to: overlayView)
            overlayView.addSubview(rg)
            rookView.isHidden = true
            
            let rookTargetCenter = rookTargetSquare.superview!.convert(rookTargetSquare.center, to: overlayView)
            
            // Setup king ghost for tap-to-move (drag already has ghostPieceView)
            var tempKingGhost: UIImageView?
            var kingTargetCenter: CGPoint?
            if self.ghostPieceView == nil, let sourceView = pieceImageViews[kingSource],
               let targetSquare = squareViews[kingTarget] {
                let kg = UIImageView(image: sourceView.image)
                kg.contentMode = .scaleAspectFit
                kg.frame = sourceView.convert(sourceView.bounds, to: overlayView)
                overlayView.addSubview(kg)
                sourceView.isHidden = true
                tempKingGhost = kg
                kingTargetCenter = targetSquare.superview!.convert(targetSquare.center, to: overlayView)
            }
            
            // Animate king ghost (from drag) to target if present
            let dragKingTargetCenter: CGPoint?
            if let ghost = self.ghostPieceView, let targetSquare = squareViews[kingTarget] {
                dragKingTargetCenter = targetSquare.superview!.convert(targetSquare.center, to: overlayView)
                _ = ghost // keep reference
            } else {
                dragKingTargetCenter = nil
            }
            
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                rg.center = rookTargetCenter
                if let kg = tempKingGhost, let ktc = kingTargetCenter {
                    kg.center = ktc
                }
                if let ghost = self.ghostPieceView, let dktc = dragKingTargetCenter {
                    ghost.center = dktc
                }
            }) { _ in
                rg.removeFromSuperview()
                tempKingGhost?.removeFromSuperview()
                completion()
            }
        } else {
            // Fallback: no rook view found, just complete
            completion()
        }
    }
}
