//
//  MixPoolMapper.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import Foundation

// MARK: - Mapper & DTOs (Data Transfer Objects)

public final class MixPoolMapper {
    
    // Root DTO representing the outermost JSON object
    private struct Root: Decodable {
        let mix_pool_id: String
        let metadata: MetadataDTO
        let difficulty_tiers: [TierDTO]
        
        var mixPool: MixPool {
            MixPool(
                id: mix_pool_id,
                metadata: MixPoolMetadata(
                    totalPuzzles: metadata.total_puzzles,
                    supportedModes: metadata.supported_modes
                ),
                difficultyTiers: difficulty_tiers.map { $0.tier }
            )
        }
    }
    
    private struct MetadataDTO: Decodable {
        let total_puzzles: Int
        let supported_modes: [String]
    }
    
    private struct TierDTO: Decodable {
        let tier_id: String
        let display_name: String
        let elo_range: String
        let accent_color_hex: String
        let description: String
        let puzzles: [PuzzleDTO]
        
        var tier: DifficultyTier {
            DifficultyTier(
                id: tier_id,
                displayName: display_name,
                eloRange: elo_range,
                accentColorHex: accent_color_hex,
                description: description,
                puzzles: puzzles.map { $0.puzzle }
            )
        }
    }
    
    // Notice how this maps the specific 'hidden_theme' string from the JSON
    // directly into the 'tags' array required by our pure Domain Puzzle entity.
    private struct PuzzleDTO: Decodable {
        let id: String
        let fen: String
        let moves: [String]
        let rating: Int
        let hidden_theme: String
        
        var puzzle: Puzzle {
            Puzzle(
                id: id,
                fen: fen,
                moves: moves,
                rating: rating,
                tags: [hidden_theme]
            )
        }
    }
    
    static func map(_ data: Data) -> FileMixPoolLoader.Result {
        guard let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(FileMixPoolLoader.Error.invalidData)
        }
        return .success(root.mixPool)
    }
}
