//
//  ThemeSettingsTests.swift
//  EssentialChessTests
//

import XCTest
import EssentialChess

final class ThemeSettingsTests: XCTestCase {

    // MARK: - RGBAColor

    func test_rgbaColor_init_setsAllComponents() {
        let color = RGBAColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.5)

        XCTAssertEqual(color.red, 0.1)
        XCTAssertEqual(color.green, 0.2)
        XCTAssertEqual(color.blue, 0.3)
        XCTAssertEqual(color.alpha, 0.5)
    }

    func test_rgbaColor_init_defaultsAlphaToOne() {
        let color = RGBAColor(red: 0.4, green: 0.5, blue: 0.6)

        XCTAssertEqual(color.alpha, 1.0)
    }

    func test_rgbaColor_equatable() {
        let color1 = RGBAColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.8)
        let color2 = RGBAColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.8)
        let color3 = RGBAColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1.0)

        XCTAssertEqual(color1, color2)
        XCTAssertNotEqual(color1, color3)
    }

    // MARK: - BoardThemeOption

    func test_boardThemeOption_allCases_containsAllExpectedThemes() {
        let cases = BoardThemeOption.allCases

        XCTAssertTrue(cases.contains(.brown))
        XCTAssertTrue(cases.contains(.green))
        XCTAssertTrue(cases.contains(.blue))
        XCTAssertTrue(cases.contains(.monochrome))
        XCTAssertEqual(cases.count, 4)
    }

    func test_boardThemeOption_rawValues() {
        XCTAssertEqual(BoardThemeOption.brown.rawValue, "Brown")
        XCTAssertEqual(BoardThemeOption.green.rawValue, "Green")
        XCTAssertEqual(BoardThemeOption.blue.rawValue, "Blue")
        XCTAssertEqual(BoardThemeOption.monochrome.rawValue, "Monochrome")
    }

    func test_boardThemeOption_lightSquareColor_isNonNilForAllCases() {
        for theme in BoardThemeOption.allCases {
            let color = theme.lightSquareColor
            XCTAssertNotNil(color, "Expected valid lightSquareColor for \(theme)")
        }
    }

    func test_boardThemeOption_darkSquareColor_isNonNilForAllCases() {
        for theme in BoardThemeOption.allCases {
            let color = theme.darkSquareColor
            XCTAssertNotNil(color, "Expected valid darkSquareColor for \(theme)")
        }
    }

    func test_boardThemeOption_highlightColor_isConsistent() {
        let expected = RGBAColor(red: 0.145, green: 0.588, blue: 0.745)

        for theme in BoardThemeOption.allCases {
            XCTAssertEqual(theme.highlightColor, expected, "Expected consistent highlight color for \(theme)")
        }
    }

    // MARK: - ThemeSettings

    func test_themeSettings_init_usesDefaultValues() {
        let settings = ThemeSettings()

        XCTAssertEqual(settings.boardTheme, .brown)
        XCTAssertEqual(settings.pieceTheme, "default")
    }

    func test_themeSettings_init_withCustomValues() {
        let settings = ThemeSettings(boardTheme: .blue, pieceTheme: "modern")

        XCTAssertEqual(settings.boardTheme, .blue)
        XCTAssertEqual(settings.pieceTheme, "modern")
    }

    func test_themeSettings_equatable() {
        let settings1 = ThemeSettings(boardTheme: .green, pieceTheme: "classic")
        let settings2 = ThemeSettings(boardTheme: .green, pieceTheme: "classic")
        let settings3 = ThemeSettings(boardTheme: .green, pieceTheme: "different")

        XCTAssertEqual(settings1, settings2)
        XCTAssertNotEqual(settings1, settings3)
    }
}
