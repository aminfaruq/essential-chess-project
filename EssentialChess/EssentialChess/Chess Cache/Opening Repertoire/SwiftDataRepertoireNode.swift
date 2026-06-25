//
//  SwiftDataRepertoireNode.swift
//  EssentialChess
//

import Foundation
import SwiftData

@Model
public final class SwiftDataRepertoireNode {
    public var fen: String
    public var movePlayed: String
    public var uciMove: String
    public var colorToMove: String
    public var parentFen: String?
    public var openingCategory: String
    
    // Repertoire Status
    public var isMainLine: Bool
    
    // SM-2 SRS Data
    public var interval: Int
    public var repetitions: Int
    public var easeFactor: Double
    public var nextReviewDate: Date?
    
    public init(
        fen: String,
        movePlayed: String,
        uciMove: String,
        colorToMove: String,
        parentFen: String?,
        openingCategory: String,
        isMainLine: Bool = false,
        interval: Int = 0,
        repetitions: Int = 0,
        easeFactor: Double = 2.5,
        nextReviewDate: Date? = nil
    ) {
        self.fen = fen
        self.movePlayed = movePlayed
        self.uciMove = uciMove
        self.colorToMove = colorToMove
        self.parentFen = parentFen
        self.openingCategory = openingCategory
        self.isMainLine = isMainLine
        self.interval = interval
        self.repetitions = repetitions
        self.easeFactor = easeFactor
        self.nextReviewDate = nextReviewDate
    }
    
    var local: RepertoireNode {
        return RepertoireNode(
            fen: fen,
            movePlayed: movePlayed,
            uciMove: uciMove,
            colorToMove: colorToMove,
            parentFen: parentFen,
            openingCategory: openingCategory,
            isMainLine: isMainLine,
            interval: interval,
            repetitions: repetitions,
            easeFactor: easeFactor,
            nextReviewDate: nextReviewDate
        )
    }
    
    func update(from local: RepertoireNode) {
        self.isMainLine = local.isMainLine
        self.interval = local.interval
        self.repetitions = local.repetitions
        self.easeFactor = local.easeFactor
        self.nextReviewDate = local.nextReviewDate
    }
}
