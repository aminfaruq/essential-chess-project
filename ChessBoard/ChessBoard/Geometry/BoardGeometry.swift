import Foundation

public struct BoardGeometry {
    public let bounds: CGSize
    public let isFlipped: Bool

    public init(bounds: CGSize, isFlipped: Bool) {
        self.bounds = bounds
        self.isFlipped = isFlipped
    }

    public var ranks: [Int] {
        return isFlipped ? [1, 2, 3, 4, 5, 6, 7, 8] : [8, 7, 6, 5, 4, 3, 2, 1]
    }

    public var files: [String] {
        return isFlipped ? ["h", "g", "f", "e", "d", "c", "b", "a"] : ["a", "b", "c", "d", "e", "f", "g", "h"]
    }

    public var squareWidth: CGFloat {
        return bounds.width / 8.0
    }

    public var squareHeight: CGFloat {
        return bounds.height / 8.0
    }

    public func squareString(at point: CGPoint) -> String? {
        let fileIndex = Int(point.x / squareWidth)
        let rankIndex = Int(point.y / squareHeight)

        guard fileIndex >= 0 && fileIndex < 8 && rankIndex >= 0 && rankIndex < 8 else {
            return nil
        }

        return "\(files[fileIndex])\(ranks[rankIndex])"
    }
}