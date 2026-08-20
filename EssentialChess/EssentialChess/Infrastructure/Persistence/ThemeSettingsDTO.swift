//
//  ThemeSettingsDTO.swift
//  EssentialChess
//

import Foundation

public struct ThemeSettingsDTO: Codable {
    private let boardTheme: String
    private let pieceTheme: String
    
    public init(settings: ThemeSettings) {
        self.boardTheme = settings.boardTheme.rawValue
        self.pieceTheme = settings.pieceTheme
    }
    
    public func toModel() -> ThemeSettings {
        ThemeSettings(
            boardTheme: BoardThemeOption(rawValue: boardTheme) ?? .brown,
            pieceTheme: pieceTheme
        )
    }
}
