import Foundation

public final class PuzzleValidator {
    private let expectedMoves: [String]

    public private(set) var currentIndex: Int = 0

    public var isCompleted: Bool {
        return currentIndex >= expectedMoves.count
    }

    public init(expectedMoves: [String]) {
        self.expectedMoves = expectedMoves
    }

    public func validate(move: String) -> Bool {
        guard !isCompleted else { return false }

        let expectedMove = expectedMoves[currentIndex]

        // Use hasPrefix to handle promotion moves where the expected move might be "e7e8q"
        // and the user move might just be evaluated as "e7e8" initially.
        if expectedMove.hasPrefix(move) {
            currentIndex += 1
            return true
        }

        return false
    }

    public func consumeNextMove() -> String? {
        guard !isCompleted else { return nil }
        let move = expectedMoves[currentIndex]
        currentIndex += 1
        return move
    }

    public func peekNextMove() -> String? {
        guard !isCompleted else { return nil }
        return expectedMoves[currentIndex]
    }
}