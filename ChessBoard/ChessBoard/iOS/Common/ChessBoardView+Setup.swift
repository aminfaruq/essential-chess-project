import UIKit

extension ChessBoardView {

    func setupContainers() {
        addSubview(boardContainer)
        boardContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            boardContainer.topAnchor.constraint(equalTo: topAnchor),
            boardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            boardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            boardContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        addSubview(overlayView)
        overlayView.isUserInteractionEnabled = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
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
            rowStack.translatesAutoresizingMaskIntoConstraints = false
            boardContainer.addSubview(rowStack)

            var rowConstraints = [
                rowStack.leadingAnchor.constraint(equalTo: boardContainer.leadingAnchor),
                rowStack.trailingAnchor.constraint(equalTo: boardContainer.trailingAnchor),
                rowStack.heightAnchor.constraint(equalTo: boardContainer.heightAnchor, multiplier: 1.0 / 8.0)
            ]
            if let prev = previousRowView {
                rowConstraints.append(rowStack.topAnchor.constraint(equalTo: prev.bottomAnchor))
            } else {
                rowConstraints.append(rowStack.topAnchor.constraint(equalTo: boardContainer.topAnchor))
            }
            NSLayoutConstraint.activate(rowConstraints)
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
                highlightOverlay.translatesAutoresizingMaskIntoConstraints = false
                squareView.addSubview(highlightOverlay)
                NSLayoutConstraint.activate([
                    highlightOverlay.topAnchor.constraint(equalTo: squareView.topAnchor),
                    highlightOverlay.leadingAnchor.constraint(equalTo: squareView.leadingAnchor),
                    highlightOverlay.trailingAnchor.constraint(equalTo: squareView.trailingAnchor),
                    highlightOverlay.bottomAnchor.constraint(equalTo: squareView.bottomAnchor)
                ])
                highlightViews[squareString] = highlightOverlay

                let checkOverlay = UIView()
                checkOverlay.backgroundColor = UIColor(red: 0.89, green: 0.15, blue: 0.15, alpha: 0.7)
                checkOverlay.isHidden = true
                checkOverlay.translatesAutoresizingMaskIntoConstraints = false
                squareView.addSubview(checkOverlay)
                NSLayoutConstraint.activate([
                    checkOverlay.topAnchor.constraint(equalTo: squareView.topAnchor),
                    checkOverlay.leadingAnchor.constraint(equalTo: squareView.leadingAnchor),
                    checkOverlay.trailingAnchor.constraint(equalTo: squareView.trailingAnchor),
                    checkOverlay.bottomAnchor.constraint(equalTo: squareView.bottomAnchor)
                ])
                checkHighlightViews[squareString] = checkOverlay

                if file == geometry.files.first {
                    let label = UILabel()
                    label.text = "\(rank)"
                    label.font = .boldSystemFont(ofSize: 12)
                    label.textColor = isLight ? darkSquareColor : lightSquareColor
                    label.translatesAutoresizingMaskIntoConstraints = false
                    squareView.addSubview(label)
                    NSLayoutConstraint.activate([
                        label.topAnchor.constraint(equalTo: squareView.topAnchor, constant: 3),
                        label.leadingAnchor.constraint(equalTo: squareView.leadingAnchor, constant: 3)
                    ])
                }

                if rank == geometry.ranks.last {
                    let label = UILabel()
                    label.text = file
                    label.font = .boldSystemFont(ofSize: 12)
                    label.textColor = isLight ? darkSquareColor : lightSquareColor
                    label.translatesAutoresizingMaskIntoConstraints = false
                    squareView.addSubview(label)
                    NSLayoutConstraint.activate([
                        label.bottomAnchor.constraint(equalTo: squareView.bottomAnchor, constant: -3),
                        label.trailingAnchor.constraint(equalTo: squareView.trailingAnchor, constant: -3)
                    ])
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