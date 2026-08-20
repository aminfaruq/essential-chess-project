import Foundation

public enum EngineGameState: Equatable {
    case inProgress
    case check(EngineColor)
    case checkmate(EngineColor)
    case stalemate
}