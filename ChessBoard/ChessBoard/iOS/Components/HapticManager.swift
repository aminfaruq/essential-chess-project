//
//  HapticManager.swift
//  NativeChessBoard
//

import UIKit

/// Manages haptic feedback for the NativeChessBoard library.
@MainActor
final class HapticManager {
    static let shared = HapticManager()
    
    /// Determines whether haptic feedback is allowed to play.
    /// Controlled by the host application.
    var isEnabled: Bool = true
    
#if DEBUG
    /// Test hook to observe triggered haptics
    var onHapticTriggered: ((String) -> Void)?
#endif
    
    private let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
    private let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
    private let rigidImpactFeedbackGenerator: UIImpactFeedbackGenerator = {
        if #available(iOS 13.0, *) {
            return UIImpactFeedbackGenerator(style: .rigid)
        } else {
            return UIImpactFeedbackGenerator(style: .medium)
        }
    }()
    
    private init() {
        selectionFeedbackGenerator.prepare()
        rigidImpactFeedbackGenerator.prepare()
    }
    
    /// Triggered when the user taps and holds a valid chess piece.
    func piecePickUp() {
        guard isEnabled else { return }
        selectionFeedbackGenerator.selectionChanged()
        selectionFeedbackGenerator.prepare()
#if DEBUG
        onHapticTriggered?("piecePickUp")
#endif
    }
    
    /// Triggered when the user drops a piece on an invalid square or makes a wrong puzzle move.
    func moveIllegal() {
        guard isEnabled else { return }
        notificationFeedbackGenerator.notificationOccurred(.error)
#if DEBUG
        onHapticTriggered?("moveIllegal")
#endif
    }
    
    /// Triggered when the user drops a piece on a square occupied by an opponent's piece.
    func moveCapture() {
        guard isEnabled else { return }
        rigidImpactFeedbackGenerator.impactOccurred()
        rigidImpactFeedbackGenerator.prepare()
#if DEBUG
        onHapticTriggered?("moveCapture")
#endif
    }
}
