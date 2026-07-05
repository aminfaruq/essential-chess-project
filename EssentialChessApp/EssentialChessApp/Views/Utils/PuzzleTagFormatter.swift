//
//  PuzzleTagFormatter.swift
//  EssentialChessApp
//
//  Created by Amin faruq
//

import Foundation

public struct PuzzleTagFormatter {
    private static let tags: [String: String] = [
        "advancedPawn": "Advanced Pawn",
        "advantage": "Advantage",
        "anastasiaMate": "Anastasia's Mate",
        "arabianMate": "Arabian Mate",
        "attackingF2F7": "Attacking f2/f7",
        "attraction": "Attraction",
        "backRankMate": "Back Rank Mate",
        "balestraMate": "Balestra Mate",
        "bishopEndgame": "Bishop Endgame",
        "blindSwineMate": "Blind Swine Mate",
        "bodenMate": "Boden's Mate",
        "capturingDefender": "Capturing Defender",
        "castling": "Castling",
        "clearance": "Clearance",
        "collinearMove": "Collinear Move",
        "cornerMate": "Corner Mate",
        "crushing": "Crushing",
        "defensiveMove": "Defensive Move",
        "deflection": "Deflection",
        "discoveredAttack": "Discovered Attack",
        "discoveredCheck": "Discovered Check",
        "doubleBishopMate": "Double Bishop Mate",
        "doubleCheck": "Double Check",
        "dovetailMate": "Dovetail Mate",
        "enPassant": "En Passant",
        "endgame": "Endgame",
        "epauletteMate": "Epaulette Mate",
        "equality": "Equality",
        "exposedKing": "Exposed King",
        "fork": "Fork",
        "hangingPiece": "Hanging Piece",
        "hookMate": "Hook Mate",
        "interference": "Interference",
        "intermezzo": "Intermezzo",
        "killBoxMate": "Kill Box Mate",
        "kingsideAttack": "Kingside Attack",
        "knightEndgame": "Knight Endgame",
        "long": "Long",
        "master": "Master",
        "masterVsMaster": "Master vs Master",
        "mate": "Checkmate",
        "mateIn1": "Mate in 1",
        "mateIn2": "Mate in 2",
        "mateIn3": "Mate in 3",
        "mateIn4": "Mate in 4",
        "mateIn5": "Mate in 5",
        "middlegame": "Middlegame",
        "morphysMate": "Morphy's Mate",
        "oneMove": "One Move",
        "opening": "Opening",
        "operaMate": "Opera Mate",
        "pawnEndgame": "Pawn Endgame",
        "pillsburysMate": "Pillsbury's Mate",
        "pin": "Pin",
        "promotion": "Promotion",
        "queenEndgame": "Queen Endgame",
        "queenRookEndgame": "Queen & Rook Endgame",
        "queensideAttack": "Queenside Attack",
        "quietMove": "Quiet Move",
        "rookEndgame": "Rook Endgame",
        "sacrifice": "Sacrifice",
        "short": "Short",
        "skewer": "Skewer",
        "smotheredMate": "Smothered Mate",
        "superGM": "Super GM",
        "swallowstailMate": "Swallow's Tail Mate",
        "trappedPiece": "Trapped Piece",
        "triangleMate": "Triangle Mate",
        "underPromotion": "Underpromotion",
        "veryLong": "Very Long",
        "vukovicMate": "Vukovic Mate",
        "xRayAttack": "X-Ray Attack",
        "zugzwang": "Zugzwang"
    ]
    
    public static func format(tag: String) -> String {
        if let formatted = tags[tag] {
            return formatted
        }
        return tag.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
