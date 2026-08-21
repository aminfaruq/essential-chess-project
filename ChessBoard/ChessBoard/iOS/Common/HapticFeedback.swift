import UIKit

@MainActor
final class HapticFeedback {
    var isEnabled: Bool = true
    
    private var onHapticTriggered: ((String) -> Void)?
    
    private let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
    private let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
    private let rigidImpactFeedbackGenerator: UIImpactFeedbackGenerator = {
        if #available(iOS 13.0, *) {
            return UIImpactFeedbackGenerator(style: .rigid)
        } else {
            return UIImpactFeedbackGenerator(style: .medium)
        }
    }()
    
    init(onHapticTriggered: ((String) -> Void)? = nil) {
        self.onHapticTriggered = onHapticTriggered
        selectionFeedbackGenerator.prepare()
        rigidImpactFeedbackGenerator.prepare()
    }
    
    func piecePickUp() {
        guard isEnabled else { return }
        selectionFeedbackGenerator.selectionChanged()
        selectionFeedbackGenerator.prepare()
        onHapticTriggered?("piecePickUp")
    }
    
    func moveIllegal() {
        guard isEnabled else { return }
        notificationFeedbackGenerator.notificationOccurred(.error)
        onHapticTriggered?("moveIllegal")
    }
    
    func moveCapture() {
        guard isEnabled else { return }
        rigidImpactFeedbackGenerator.impactOccurred()
        rigidImpactFeedbackGenerator.prepare()
        onHapticTriggered?("moveCapture")
    }
}
