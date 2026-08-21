//
//  CurriculumRoute.swift
//  EssentialChessApp
//
//  Created by App on 21/08/26.
//

import Foundation
import EssentialChessUI

public enum CurriculumRoute: Hashable {
    case sectionDetail(SectionUIModel)
    case puzzleSession(title: String, puzzles: [PuzzleUIModel])
    case learnPiecesSession(themeId: String, title: String, puzzles: [PuzzleUIModel], initialIndex: Int)
}
