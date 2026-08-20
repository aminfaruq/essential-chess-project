import Foundation

public enum PGNAnnotation: Hashable, Sendable {
    case whiteNumber(Int)
    case blackNumber(Int)
    case move(san: String, moveId: String)
    case positionAssessment(String)
    case variationStart
    case variationEnd
}