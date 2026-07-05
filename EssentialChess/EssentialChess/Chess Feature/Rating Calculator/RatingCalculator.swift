import Foundation

public struct RatingCalculator {
    private let placementKFactor: Double = 100.0
    private let regularKFactor: Double = 32.0 // Standard FIDE K-Factor for general players
    public let baseProvisionalRating: Double = 1500.0
    private let minimumRating: Double = 100.0
    
    public init() {}
    
    private func expectedScore(userRating: Double, puzzleRating: Double) -> Double {
        let exponent = (puzzleRating - userRating) / 400.0
        return 1.0 / (1.0 + pow(10.0, exponent))
    }
    
    public func calculatePlacementRating(current: Double, puzzleRating: Double, isCorrect: Bool) -> Double {
        return calculate(current: current, puzzleRating: puzzleRating, isCorrect: isCorrect, kFactor: placementKFactor)
    }
    
    public func calculateRegularRating(current: Double, puzzleRating: Double, isCorrect: Bool) -> Double {
        return calculate(current: current, puzzleRating: puzzleRating, isCorrect: isCorrect, kFactor: regularKFactor)
    }
    
    private func calculate(current: Double, puzzleRating: Double, isCorrect: Bool, kFactor: Double) -> Double {
        let actual = isCorrect ? 1.0 : 0.0
        let expected = expectedScore(userRating: current, puzzleRating: puzzleRating)
        let delta = kFactor * (actual - expected)
        return max(minimumRating, current + delta)
    }
    
    public func placementBracket(rating: Double) -> String {
        switch rating {
        case ..<800:   return "500-800"
        case ..<1200:  return "800-1200"
        case ..<1600:  return "1200-1600"
        default:       return "1600-2000"
        }
    }
}
