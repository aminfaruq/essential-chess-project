//
//  RepertoireNode.swift
//  EssentialChess
//

import Foundation

public struct RepertoireNode: Hashable, Equatable {
    public let fen: String
    public let movePlayed: String
    public let uciMove: String
    public let colorToMove: String
    public let parentFen: String?
    public let openingCategory: String
    
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
}
