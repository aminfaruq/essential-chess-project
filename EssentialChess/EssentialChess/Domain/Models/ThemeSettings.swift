//
//  ThemeSettings.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import Foundation

// MARK: - Pure Color Representation
public struct RGBAColor: Equatable, Codable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double
    
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

// MARK: - Theme Option
public enum BoardThemeOption: String, CaseIterable, Codable {
    case brown = "Brown"
    case green = "Green"
    case blue  = "Blue"
    case monochrome = "Monochrome"
    
    public var lightSquareColor: RGBAColor {
        switch self {
        case .brown: return RGBAColor(red: 0.94, green: 0.85, blue: 0.71)
        case .green: return RGBAColor(red: 0.93, green: 0.93, blue: 0.82)
        case .blue:  return RGBAColor(red: 0.89, green: 0.93, blue: 0.96)
        case .monochrome: return RGBAColor(red: 0.92, green: 0.92, blue: 0.92)
        }
    }
    
    public var darkSquareColor: RGBAColor {
        switch self {
        case .brown: return RGBAColor(red: 0.71, green: 0.53, blue: 0.39)
        case .green: return RGBAColor(red: 0.46, green: 0.59, blue: 0.34)
        case .blue:  return RGBAColor(red: 0.43, green: 0.58, blue: 0.73)
        case .monochrome: return RGBAColor(red: 0.55, green: 0.55, blue: 0.55)
        }
    }
    
    public var highlightColor: RGBAColor {
        // Highlight color remains consistent across all themes
        return RGBAColor(red: 0.145, green: 0.588, blue: 0.745)
    }
}

// MARK: - Theme Settings Entity
public struct ThemeSettings: Equatable, Codable {
    public let boardTheme: BoardThemeOption
    public let pieceTheme: String
    
    public init(boardTheme: BoardThemeOption = .brown, pieceTheme: String = "default") {
        self.boardTheme = boardTheme
        self.pieceTheme = pieceTheme
    }
}
