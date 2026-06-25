import UIKit
internal import SnapKit

extension AnalysisChessBoardView {
    
    func renderPieces() {
        guard let engine = engine else { return }
        
        pieceImageViews.values.forEach { $0.removeFromSuperview() }
        pieceImageViews.removeAll()
        checkHighlightViews.values.forEach { $0.isHidden = true }
        
        let checkColor = engine.kingInCheckColor
        
        for rank in 1...8 {
            for file in ["a", "b", "c", "d", "e", "f", "g", "h"] {
                let squareString = "\(file)\(rank)"
                guard let piece = engine.piece(at: squareString),
                      let squareView = squareViews[squareString] else { continue }
                
                if piece.kind == .king && piece.color == checkColor {
                    checkHighlightViews[squareString]?.isHidden = false
                }
                
                let colorLetter = piece.color == .white ? "w" : "b"
                let pieceLetter: String
                switch piece.kind {
                case .pawn: pieceLetter = "p"; case .knight: pieceLetter = "n"; case .bishop: pieceLetter = "b"
                case .rook: pieceLetter = "r"; case .queen: pieceLetter = "q"; case .king: pieceLetter = "k"
                }
                
                if let image = UIImage(named: "\(currentPieceTheme)_\(colorLetter)\(pieceLetter)") {
                    let imageView = UIImageView(image: image)
                    imageView.contentMode = .scaleAspectFit
                    squareView.addSubview(imageView)
                    imageView.snp.makeConstraints { make in make.edges.equalToSuperview().inset(4) }
                    pieceImageViews[squareString] = imageView
                }
            }
        }
    }
    
    func cleanupGhost() {
        ghostPieceView?.removeFromSuperview()
        ghostPieceView = nil
    }
    
    func animateSnapback(completion: (() -> Void)? = nil) {
        guard let ghost = ghostPieceView else { completion?(); return }
        UIView.animate(withDuration: 0.2, animations: {
            ghost.center = self.dragStartOriginalCenter
            ghost.transform = .identity
        }) { [weak self] _ in
            self?.renderPieces()
            ghost.removeFromSuperview()
            self?.ghostPieceView = nil
            completion?()
        }
    }
    
    func isPromotionMove(from source: String, to target: String) -> Bool {
        guard let piece = engine?.piece(at: source), piece.kind == .pawn else { return false }
        
        guard engine?.legalMoves(for: source).contains(target) == true else { return false }
        
        let targetRank = target.last
        return (piece.color == .white && targetRank == "8") || (piece.color == .black && targetRank == "1")
    }
    
    func showPromotionDialog(from sourceStr: String, to targetStr: String, completion: @escaping (String?) -> Void) {
        guard let engine = engine else { return }
        self.isBoardLocked = true
        let colorLetter = engine.sideToMove == .white ? "w" : "b"
        
        let promotionView = PromotionOverlayView(colorLetter: colorLetter, themePrefix: currentPieceTheme) { [weak self] choice in
            self?.subviews.compactMap { $0 as? PromotionOverlayView }.forEach { $0.removeFromSuperview() }
            self?.isBoardLocked = false
            completion(choice)
        }
        
        promotionView.alpha = 0
        self.addSubview(promotionView)
        promotionView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        UIView.animate(withDuration: 0.2) { promotionView.alpha = 1.0 }
    }
    
    func clearHighlights() {
        highlightViews.values.forEach { $0.isHidden = true }
        squareViews.values.forEach { $0.layer.borderWidth = 0 }
    }
    
    func showLegalMoveHints(for squareStr: String) {
        clearLegalMoveHints()
        let legalSquares = engine?.legalMoves(for: squareStr) ?? []
        
        let squareSize = bounds.width / 8.0
        let dotSize = squareSize * 0.25
        let captureRingWidth = squareSize * 0.08
        
        for sqStr in legalSquares {
            if let sqView = squareViews[sqStr] {
                let hint = UIView()
                hint.isUserInteractionEnabled = false
                
                if engine?.piece(at: sqStr) != nil {
                    hint.layer.borderColor = UIColor.black.withAlphaComponent(0.25).cgColor
                    hint.layer.borderWidth = captureRingWidth
                    hint.layer.cornerRadius = squareSize / 2.0
                } else {
                    hint.backgroundColor = UIColor.black.withAlphaComponent(0.25)
                    hint.layer.cornerRadius = dotSize / 2.0
                }
                
                sqView.addSubview(hint)
                if engine?.piece(at: sqStr) != nil {
                    hint.snp.makeConstraints { make in make.edges.equalToSuperview() }
                } else {
                    hint.snp.makeConstraints { make in make.center.equalToSuperview(); make.width.height.equalTo(dotSize) }
                }
                legalMoveHintViews.append(hint)
            }
        }
    }
    
    func clearLegalMoveHints() {
        legalMoveHintViews.forEach { $0.removeFromSuperview() }
        legalMoveHintViews.removeAll()
    }
    
    public func clearSolutionArrow() {
        solutionArrowContainer?.removeFromSuperview()
        solutionArrowContainer = nil
    }

    public func drawArrow(from sourceStr: String, to targetStr: String, color: UIColor, isPersistent: Bool = true) {
        if isPersistent {
            clearSolutionArrow()
        }
        
        guard let srcView = squareViews[sourceStr], let tgtView = squareViews[targetStr] else { return }
        let startPoint = overlayView.convert(srcView.center, from: srcView.superview)
        let endPoint = overlayView.convert(tgtView.center, from: tgtView.superview)
        let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
        
        let offset: CGFloat = 10.0
        let tipPoint = CGPoint(x: endPoint.x - cos(angle) * offset, y: endPoint.y - sin(angle) * offset)
        let headLength: CGFloat = 16.0
        let headAngle = CGFloat.pi / 6
        
        let p1 = CGPoint(x: tipPoint.x - headLength * cos(angle - headAngle), y: tipPoint.y - headLength * sin(angle - headAngle))
        let p2 = CGPoint(x: tipPoint.x - headLength * cos(angle + headAngle), y: tipPoint.y - headLength * sin(angle + headAngle))
        let midBasePoint = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
        
        let path = UIBezierPath()
        path.move(to: startPoint)
        path.addLine(to: midBasePoint)
        
        let arrowContainer = UIView(frame: overlayView.bounds)
        arrowContainer.isUserInteractionEnabled = false
        overlayView.addSubview(arrowContainer)
        
        let arrowLayer = CAShapeLayer()
        arrowLayer.path = path.cgPath
        arrowLayer.strokeColor = color.cgColor
        arrowLayer.lineWidth = 6
        arrowLayer.lineCap = .round
        
        let headPath = UIBezierPath()
        headPath.move(to: tipPoint)
        headPath.addLine(to: p1)
        headPath.addLine(to: p2)
        headPath.close()
        
        let headLayer = CAShapeLayer()
        headLayer.path = headPath.cgPath
        headLayer.fillColor = color.cgColor
        
        arrowLayer.addSublayer(headLayer)
        arrowContainer.layer.addSublayer(arrowLayer)
        
        if isPersistent {
            self.solutionArrowContainer = arrowContainer
        } else {
            UIView.animate(withDuration: 0.3, delay: 0.5, options: .curveEaseOut, animations: {
                arrowContainer.alpha = 0
            }) { _ in
                arrowContainer.removeFromSuperview()
            }
        }
    }
}
