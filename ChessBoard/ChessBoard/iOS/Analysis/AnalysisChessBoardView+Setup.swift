import UIKit
internal import SnapKit

extension AnalysisChessBoardView {
    
    func setupContainers() {
        addSubview(boardContainer)
        boardContainer.snp.makeConstraints { make in make.edges.equalToSuperview() }
        
        addSubview(overlayView)
        overlayView.isUserInteractionEnabled = false
        overlayView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    
    func setupBoardGrid() {
        boardContainer.subviews.forEach { $0.removeFromSuperview() }
        squareViews.removeAll()
        highlightViews.removeAll()
        checkHighlightViews.removeAll()
        
        var previousRowView: UIView? = nil
        
        for rank in geometry.ranks {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            boardContainer.addSubview(rowStack)
            
            rowStack.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                if let prev = previousRowView { make.top.equalTo(prev.snp.bottom) }
                else { make.top.equalToSuperview() }
                make.height.equalToSuperview().multipliedBy(1.0 / 8.0)
            }
            previousRowView = rowStack
            
            for file in geometry.files {
                let squareString = "\(file)\(rank)"
                let squareView = UIView()
                let isLight = (Int(file.unicodeScalars.first!.value) + rank) % 2 != 0
                squareView.backgroundColor = isLight ? lightSquareColor : darkSquareColor
                
                rowStack.addArrangedSubview(squareView)
                squareViews[squareString] = squareView
                squareView.accessibilityIdentifier = squareString
                
                let highlightOverlay = UIView()
                highlightOverlay.backgroundColor = highlightColor
                highlightOverlay.isHidden = true
                squareView.addSubview(highlightOverlay)
                highlightOverlay.snp.makeConstraints { make in make.edges.equalToSuperview() }
                highlightViews[squareString] = highlightOverlay
                
                let checkOverlay = UIView()
                checkOverlay.backgroundColor = UIColor(red: 0.89, green: 0.15, blue: 0.15, alpha: 0.7)
                checkOverlay.isHidden = true
                squareView.addSubview(checkOverlay)
                checkOverlay.snp.makeConstraints { make in make.edges.equalToSuperview() }
                checkHighlightViews[squareString] = checkOverlay
                
                if file == geometry.files.first {
                    let label = UILabel()
                    label.text = "\(rank)"
                    label.font = .boldSystemFont(ofSize: 12)
                    label.textColor = isLight ? darkSquareColor : lightSquareColor
                    squareView.addSubview(label)
                    label.snp.makeConstraints { make in make.top.leading.equalToSuperview().inset(3) }
                }
                
                if rank == geometry.ranks.last {
                    let label = UILabel()
                    label.text = file
                    label.font = .boldSystemFont(ofSize: 12)
                    label.textColor = isLight ? darkSquareColor : lightSquareColor
                    squareView.addSubview(label)
                    label.snp.makeConstraints { make in make.bottom.trailing.equalToSuperview().inset(3) }
                }
            }
        }
    }
    
    func setupGestures() {
        interactionHandler.setup(in: boardContainer) { [weak self] point in
            return self?.geometry.squareString(at: point)
        }
        
        interactionHandler.onSquareTapped = { [weak self] sq in self?.processTap(on: sq) }
        interactionHandler.onDragBegan = { [weak self] sq, _ in return self?.processDragBegan(at: sq) ?? false }
        interactionHandler.onDragChanged = { [weak self] trans in self?.processDragChanged(translation: trans) }
        interactionHandler.onPieceMoved = { [weak self] src, tgt in self?.processDragEnded(from: src, to: tgt) }
        interactionHandler.onDragCancelled = { [weak self] in
            self?.clearLegalMoveHints()
            self?.animateSnapback { self?.clearHighlights() }
        }
    }
}
