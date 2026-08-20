import UIKit

extension ChessBoardView {

    func processTap(on clickedSquareStr: String) {
        guard !interactionLocked, let engine = engine else { return }

        if let sourceStr = selectedSquareString {
            if sourceStr == clickedSquareStr {
                selectedSquareString = nil
                clearLegalMoveHints(); clearHighlights(); return
            }

            if switchesSelectionOnOwnPieceTap,
               let clickedPiece = engine.piece(at: clickedSquareStr), clickedPiece.color == engine.sideToMove {
                selectedSquareString = clickedSquareStr
                clearLegalMoveHints()
                clearHighlights()
                highlightViews[clickedSquareStr]?.isHidden = false
                showLegalMoveHints(for: clickedSquareStr)
                return
            }

            if isPromotionMove(from: sourceStr, to: clickedSquareStr) {
                showPromotionDialog(from: sourceStr, to: clickedSquareStr) { [weak self] choice in
                    if let choice = choice {
                        self?.handleMove(from: sourceStr, to: clickedSquareStr, promotionChar: choice)
                    }
                }
            } else {
                handleMove(from: sourceStr, to: clickedSquareStr)
            }
        } else {
            if let piece = engine.piece(at: clickedSquareStr), piece.color == engine.sideToMove {
                selectedSquareString = clickedSquareStr
                clearHighlights()
                highlightViews[clickedSquareStr]?.isHidden = false
                showLegalMoveHints(for: clickedSquareStr)
            }
        }
    }

    func processDragBegan(at startSquareStr: String) -> Bool {
        guard !interactionLocked, let engine = engine else { return false }
        guard let piece = engine.piece(at: startSquareStr), piece.color == engine.sideToMove,
              let originalPieceView = pieceImageViews[startSquareStr] else { return false }

        showLegalMoveHints(for: startSquareStr)

        let ghost = UIImageView(image: originalPieceView.image)
        ghost.contentMode = .scaleAspectFit
        ghost.frame = originalPieceView.convert(originalPieceView.bounds, to: overlayView)
        overlayView.addSubview(ghost)
        ghostPieceView = ghost
        dragStartOriginalCenter = ghost.center

        originalPieceView.isHidden = true
        UIView.animate(withDuration: 0.1) { ghost.transform = CGAffineTransform(scaleX: 1.3, y: 1.3) }

        selectedSquareString = nil
        clearHighlights()
        highlightViews[startSquareStr]?.isHidden = false
        feedback.piecePickUp()
        return true
    }

    func processDragChanged(translation: CGPoint) {
        ghostPieceView?.center = CGPoint(x: dragStartOriginalCenter.x + translation.x, y: dragStartOriginalCenter.y + translation.y)
    }

    func processDragEnded(from sourceStr: String, to targetStr: String) {
        clearLegalMoveHints()
        if isPromotionMove(from: sourceStr, to: targetStr) {
            if let targetView = squareViews[targetStr] {
                UIView.animate(withDuration: 0.1) { self.ghostPieceView?.center = targetView.center }
            }
            showPromotionDialog(from: sourceStr, to: targetStr) { [weak self] choice in
                if let choice = choice {
                    self?.handleMove(from: sourceStr, to: targetStr, promotionChar: choice)
                } else { self?.animateSnapback { self?.clearHighlights() } }
            }
        } else {
            handleMove(from: sourceStr, to: targetStr)
        }
    }
}