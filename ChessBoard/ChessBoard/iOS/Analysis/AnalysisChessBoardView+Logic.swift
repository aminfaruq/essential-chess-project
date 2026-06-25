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
        
        if engine.move(from: sourceStr, to: targetStr, promotion: promotionChar) {
            if isCapture {
                HapticManager.shared.moveCapture()
                SoundManager.shared.playCapture()
            } else {
                SoundManager.shared.playMove()
            }
            
            clearHighlights()
            highlightViews[sourceStr]?.isHidden = false
            highlightViews[targetStr]?.isHidden = false
            
            selectedSquareString = nil
            
            if let ghost = ghostPieceView, let targetView = squareViews[targetStr] {
                UIView.animate(withDuration: 0.15, animations: {
                    ghost.center = self.overlayView.convert(targetView.center, from: targetView.superview)
                }) { [weak self] _ in
                    self?.renderPieces()
                    ghost.removeFromSuperview()
                    self?.ghostPieceView = nil
                    
                    let uci = "\(sourceStr)\(targetStr)\(promotionChar ?? "")"
                    self?.onUserMoved?(uci)
                }
            } else {
                renderPieces()
                let uci = "\(sourceStr)\(targetStr)\(promotionChar ?? "")"
                onUserMoved?(uci)
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
        
        // Cek capture sebelum move
        let isCapture = engine.piece(at: targetStr) != nil
        
        if engine.move(from: sourceStr, to: targetStr, promotion: promoStr) {
            guard let srcView = squareViews[sourceStr],
                  let tgtView = squareViews[targetStr],
                  let originalPieceView = pieceImageViews[sourceStr] else {
                renderPieces()
                completion?()
                return
            }
            
            let ghost = UIImageView(image: originalPieceView.image)
            ghost.contentMode = .scaleAspectFit
            ghost.frame = originalPieceView.convert(originalPieceView.bounds, to: overlayView)
            overlayView.addSubview(ghost)
            
            originalPieceView.isHidden = true
            clearHighlights()
            highlightViews[sourceStr]?.isHidden = false
            
            let targetCenter = overlayView.convert(tgtView.center, from: tgtView.superview)
            
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
                ghost.center = targetCenter
            }) { [weak self] _ in
                if isCapture {
                    SoundManager.shared.playCapture()
                } else {
                    SoundManager.shared.playMove()
                }
                self?.highlightViews[targetStr]?.isHidden = false
                self?.renderPieces()
                ghost.removeFromSuperview()
                completion?()
            }
        } else {
            completion?()
        }
    }
}
