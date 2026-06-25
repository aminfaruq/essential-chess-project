//
//  Untitled.swift
//  NativeChessBoard
//
//  Created by Amin faruq on 08/06/26.
//

import UIKit

/// Handles touch and drag interactions for the chess board, translating them into logical chess events.
@MainActor
public final class BoardInteractionHandler {
    
    // MARK: - Callbacks
    
    public var onSquareTapped: ((String) -> Void)?
    public var onDragBegan: ((String, CGPoint) -> Bool)?
    public var onDragChanged: ((CGPoint) -> Void)?
    public var onPieceMoved: ((String, String) -> Void)?
    public var onDragCancelled: (() -> Void)?
    
    // MARK: - Dependencies
    
    private var squareResolver: ((CGPoint) -> String?)?
    
    // MARK: - Internal State
    
    private var dragStartSquare: String?
    
    public init() {}
    
    /// Attaches the necessary gesture recognizers to the target view.
    /// - Parameters:
    ///   - view: The view that will receive touch events.
    ///   - squareResolver: A closure that translates a physical CGPoint into an algebraic square string.
    public func setup(in view: UIView, squareResolver: @escaping (CGPoint) -> String?) {
        self.squareResolver = squareResolver
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
    }
    
    // MARK: - Gesture Processing
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        let location = gesture.location(in: view)
        
        if let squareStr = squareResolver?(location) {
            onSquareTapped?(squareStr)
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let location = gesture.location(in: view)
        
        switch gesture.state {
        case .began:
            if let startSquareStr = squareResolver?(location) {
                let accepted = onDragBegan?(startSquareStr, location) ?? false
                if accepted {
                    dragStartSquare = startSquareStr
                } else {
                    gesture.state = .cancelled
                }
            } else {
                gesture.state = .cancelled
            }
            
        case .changed:
            let translation = gesture.translation(in: view)
            onDragChanged?(translation)
            
        case .ended:
            let dropSquareStr = squareResolver?(location)
            
            if let targetStr = dropSquareStr, let sourceStr = dragStartSquare, targetStr != sourceStr {
                onPieceMoved?(sourceStr, targetStr)
            } else {
                onDragCancelled?()
            }
            dragStartSquare = nil
            
        case .cancelled, .failed:
            onDragCancelled?()
            dragStartSquare = nil
            
        default: break
        }
    }
    
    // MARK: - Testable Interface
    
    public func simulateTap(on square: String) {
        onSquareTapped?(square)
    }
    
    public func simulateDragEnded(source: String, target: String) {
        onPieceMoved?(source, target)
    }
    
    public func simulateDragCancelled() {
        onDragCancelled?()
    }
}
