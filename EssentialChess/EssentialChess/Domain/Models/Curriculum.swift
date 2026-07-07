//
//  Curriculum.swift
//  EssentialChess
//
//  Created by Amin faruq on 09/06/26.
//

import Foundation

public struct Curriculum: Equatable {
    public let version: String
    public let metadata: CurriculumMetadata
    public let sections: [EloSection]
    
    public init(version: String, metadata: CurriculumMetadata, sections: [EloSection]) {
        self.version = version
        self.metadata = metadata
        self.sections = sections
    }
}

public struct CurriculumMetadata: Equatable {
    public let description: String
    public let totalSections: Int
    public let targetPuzzlesPerSubTheme: Int
    public let targetPuzzlesPerExam: Int?
    
    public init(description: String, totalSections: Int, targetPuzzlesPerSubTheme: Int, targetPuzzlesPerExam: Int?) {
        self.description = description
        self.totalSections = totalSections
        self.targetPuzzlesPerSubTheme = targetPuzzlesPerSubTheme
        self.targetPuzzlesPerExam = targetPuzzlesPerExam
    }
}

public struct EloSection: Equatable {
    public let id: String
    public let title: String
    public let eloRange: String
    public let isLockedByDefault: Bool
    public let categories: [Category]
    
    public init(id: String, title: String, eloRange: String, isLockedByDefault: Bool, categories: [Category]) {
        self.id = id
        self.title = title
        self.eloRange = eloRange
        self.isLockedByDefault = isLockedByDefault
        self.categories = categories
    }
    
    public var eloFloor: Double {
        let parts = eloRange.split(separator: "-")
        return Double(parts.first.map(String.init) ?? "500") ?? 500
    }
}

public struct Category: Equatable {
    public let id: String
    public let title: String
    public let isExamMode: Bool
    public let description: String?
    public let totalPuzzles: Int?
    public let puzzles: [Puzzle]?
    public let subThemes: [SubTheme]?
    
    public init(id: String, title: String, isExamMode: Bool, description: String?, totalPuzzles: Int?, puzzles: [Puzzle]?, subThemes: [SubTheme]?) {
        self.id = id
        self.title = title
        self.isExamMode = isExamMode
        self.description = description
        self.totalPuzzles = totalPuzzles
        self.puzzles = puzzles
        self.subThemes = subThemes
    }
}

public struct SubTheme: Equatable {
    public let id: String
    public let title: String
    public let totalPuzzles: Int
    public let puzzles: [Puzzle]
    
    public init(id: String, title: String, totalPuzzles: Int, puzzles: [Puzzle]) {
        self.id = id
        self.title = title
        self.totalPuzzles = totalPuzzles
        self.puzzles = puzzles
    }
}

public struct Puzzle: Equatable {
    public let id: String
    public let fen: String
    public let moves: [String]
    public let rating: Int
    public let tags: [String]
    
    public init(id: String, fen: String, moves: [String], rating: Int, tags: [String]) {
        self.id = id
        self.fen = fen
        self.moves = moves
        self.rating = rating
        self.tags = tags
    }
}
