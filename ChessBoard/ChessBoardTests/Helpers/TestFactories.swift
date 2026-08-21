import Foundation
@testable import ChessBoard

func anyNSError() -> NSError {
    NSError(domain: "any error", code: 0)
}

func anyString() -> String {
    "any string"
}

func anySquare() -> String {
    "e4"
}

func anyMoveString() -> String {
    "e2e4"
}

func makePGNMove() -> PGNAnnotation {
    .move(san: anyString(), moveId: anyString())
}