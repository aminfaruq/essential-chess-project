//
//  PromotionOverlayView.swift
//  NativeChessBoard
//
//  Created by Amin faruq on 08/06/26.
//

import UIKit
internal import SnapKit

/// A standalone modal view that presents pawn promotion choices to the user.
public final class PromotionOverlayView: UIView {
    
    // MARK: - Callbacks
    
    /// Triggered when the user selects a piece (returns "q", "n", "r", "b") or taps outside to cancel (returns nil).
    private let onSelection: (String?) -> Void
    
    // MARK: - Initialization
    
    public init(colorLetter: String, themePrefix: String, onSelection: @escaping (String?) -> Void) {
        self.onSelection = onSelection
        super.init(frame: .zero)
        setupUI(colorLetter: colorLetter, themePrefix: themePrefix)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI(colorLetter: String, themePrefix: String) {
        self.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        let cancelTap = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        cancelTap.delegate = self
        self.addGestureRecognizer(cancelTap)
        
        let stackContainer = UIView()
        if colorLetter == "b" {
            stackContainer.backgroundColor = UIColor(white: 0.85, alpha: 0.95)
        } else {
            stackContainer.backgroundColor = UIColor(white: 0.15, alpha: 0.95)
        }
        stackContainer.layer.cornerRadius = 12
        self.addSubview(stackContainer)
        
        stackContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.distribution = .fillEqually
        stackContainer.addSubview(stack)
        
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        let choices = ["q", "n", "r", "b"]
        
        for choice in choices {
            let pieceImageName = "\(themePrefix)_\(colorLetter)\(choice)"
            let imageView = UIImageView(image: UIImage(named: pieceImageName))
            imageView.contentMode = .scaleAspectFit
            imageView.isUserInteractionEnabled = true
            imageView.snp.makeConstraints { make in
                make.width.height.equalTo(60)
            }
            
            let tap = PromotionTapGesture(target: self, action: #selector(handlePieceTap(_:)))
            tap.choice = choice
            imageView.addGestureRecognizer(tap)
            
            stack.addArrangedSubview(imageView)
        }
    }
    
    // MARK: - Actions
    
    @objc private func handleBackgroundTap() {
        simulateCancellation()
    }
    
    @objc private func handlePieceTap(_ sender: PromotionTapGesture) {
        if let choice = sender.choice {
            simulateSelection(choice: choice)
        }
    }
    
    // MARK: - Testable Interface
    
    /// Simulates a piece selection (used primarily for testing).
    public func simulateSelection(choice: String) {
        onSelection(choice)
    }
    
    /// Simulates a background tap cancellation (used primarily for testing).
    public func simulateCancellation() {
        onSelection(nil)
    }
    
    private class PromotionTapGesture: UITapGestureRecognizer {
        var choice: String?
    }
}

extension PromotionOverlayView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only trigger background tap if the touch is directly on the background view,
        // not on the popup container or the piece images.
        return touch.view == self
    }
}
