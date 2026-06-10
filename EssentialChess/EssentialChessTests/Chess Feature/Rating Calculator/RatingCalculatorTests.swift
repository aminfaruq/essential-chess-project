//
//  RatingCalculatorTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import XCTest
import EssentialChess

final class RatingCalculatorTests: XCTestCase {
    
    func test_init_setsBaseProvisionalRating() {
        let sut = RatingCalculator()
        XCTAssertEqual(sut.baseProvisionalRating, 1500.0)
    }
    
    func test_calculatePlacementRating_increasesRatingOnCorrectAnswer() {
        let sut = RatingCalculator()
        
        // When user and puzzle have the exact same rating (1500), the expected score is 0.5.
        // If the answer is correct (actual = 1.0), the delta is 100 * (1.0 - 0.5) = +50.
        let newRating = sut.calculatePlacementRating(current: 1500.0, puzzleRating: 1500.0, isCorrect: true)
        
        XCTAssertEqual(newRating, 1550.0)
    }
    
    func test_calculatePlacementRating_decreasesRatingOnIncorrectAnswer() {
        let sut = RatingCalculator()
        
        // When user and puzzle have the exact same rating (1500), the expected score is 0.5.
        // If the answer is incorrect (actual = 0.0), the delta is 100 * (0.0 - 0.5) = -50.
        let newRating = sut.calculatePlacementRating(current: 1500.0, puzzleRating: 1500.0, isCorrect: false)
        
        XCTAssertEqual(newRating, 1450.0)
    }
    
    func test_calculatePlacementRating_doesNotDropBelowMinimumRating() {
        let sut = RatingCalculator()
        
        // If a 100-rated user fails a 2000-rated puzzle, the delta is negative.
        // However, the domain rule states the rating cannot drop below 100.0.
        let newRating = sut.calculatePlacementRating(current: 100.0, puzzleRating: 2000.0, isCorrect: false)
        
        XCTAssertEqual(newRating, 100.0)
    }
    
    func test_placementBracket_returnsCorrectBrackets() {
        let sut = RatingCalculator()
        
        // Under 800
        XCTAssertEqual(sut.placementBracket(rating: 400.0), "500-800")
        XCTAssertEqual(sut.placementBracket(rating: 799.9), "500-800")
        
        // 800 to under 1200
        XCTAssertEqual(sut.placementBracket(rating: 800.0), "800-1200")
        XCTAssertEqual(sut.placementBracket(rating: 1199.9), "800-1200")
        
        // 1200 to under 1600
        XCTAssertEqual(sut.placementBracket(rating: 1200.0), "1200-1600")
        XCTAssertEqual(sut.placementBracket(rating: 1599.9), "1200-1600")
        
        // 1600 and above
        XCTAssertEqual(sut.placementBracket(rating: 1600.0), "1600-2000")
        XCTAssertEqual(sut.placementBracket(rating: 2500.0), "1600-2000")
    }
}
