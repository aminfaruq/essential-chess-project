//
//  CurriculumMapper.swift
//  EssentialChess
//
//  Created by Amin faruq on 09/06/26.
//

// MARK: - Mapper & DTOs (Data Transfer Objects)

import Foundation
// These DTOs are kept PRIVATE so that the details of 'Codable' and 'snake_case'
// never leak outside of this file.
public final class CurriculumMapper {
    
    private struct Root: Decodable {
        let curriculum_version: String
        let metadata: MetadataDTO
        let elo_sections: [SectionDTO]
        
        var curriculum: Curriculum {
            Curriculum(
                version: curriculum_version,
                metadata: CurriculumMetadata(
                    description: metadata.description,
                    totalSections: metadata.total_sections,
                    targetPuzzlesPerSubTheme: metadata.target_puzzles_per_sub_theme,
                    targetPuzzlesPerExam: metadata.target_puzzles_per_exam
                ),
                sections: elo_sections.map { $0.section }
            )
        }
    }
    
    private struct MetadataDTO: Decodable {
        let description: String
        let total_sections: Int
        let target_puzzles_per_sub_theme: Int
        let target_puzzles_per_exam: Int?
    }
    
    private struct SectionDTO: Decodable {
        let section_id: String
        let title: String
        let elo_range: String
        let is_locked_by_default: Bool
        let categories: [CategoryDTO]
        
        var section: EloSection {
            EloSection(
                id: section_id,
                title: title,
                eloRange: elo_range,
                isLockedByDefault: is_locked_by_default,
                categories: categories.map { $0.category }
            )
        }
    }
    
    private struct CategoryDTO: Decodable {
        let category_id: String
        let title: String
        let is_exam_mode: Bool
        let description: String?
        let total_puzzles: Int?
        let puzzles: [PuzzleDTO]?
        let sub_themes: [SubThemeDTO]?
        
        var category: Category {
            Category(
                id: category_id,
                title: title,
                isExamMode: is_exam_mode,
                description: description,
                totalPuzzles: total_puzzles,
                puzzles: puzzles?.map { $0.puzzle },
                subThemes: sub_themes?.map { $0.subTheme }
            )
        }
    }
    
    private struct SubThemeDTO: Decodable {
        let sub_theme_id: String
        let title: String
        let total_puzzles: Int
        let puzzles: [PuzzleDTO]
        
        var subTheme: SubTheme {
            SubTheme(id: sub_theme_id, title: title, totalPuzzles: total_puzzles, puzzles: puzzles.map { $0.puzzle })
        }
    }
    
    private struct PuzzleDTO: Decodable {
        let id: String
        let fen: String
        let moves: [String]
        let rating: Int
        let tags: [String]
        
        var puzzle: Puzzle {
            Puzzle(id: id, fen: fen, moves: moves, rating: rating, tags: tags)
        }
    }
    
    static func map(_ data: Data) -> FileCurriculumLoader.Result {
        guard let root = try? JSONDecoder().decode(Root.self, from: data) else {
            // If decoding fails (invalid JSON), return invalidData error
            return .failure(.invalidData)
        }
        // On success, return a clean domain entity!
        return .success(root.curriculum)
    }
}
