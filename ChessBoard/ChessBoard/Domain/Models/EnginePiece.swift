import Foundation

public struct EnginePiece: Equatable {
    public let kind: EnginePieceKind
    public let color: EngineColor
    
    public init(kind: EnginePieceKind, color: EngineColor) {
        self.kind = kind
        self.color = color
    }
}
