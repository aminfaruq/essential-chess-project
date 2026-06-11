![Swift](https://img.shields.io/badge/Swift-5.9+-orange?style=flat-square&logo=swift)
![iOS](https://img.shields.io/badge/iOS-16.0+-black?style=flat-square&logo=apple)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture%20%7C%20MVVM-blue?style=flat-square)
![Framework](https://img.shields.io/badge/Framework-SwiftUI%20%7C%20Combine-blueviolet?style=flat-square)

An offline-first, iOS educational chess application designed to guide players through a gamified, structured tactical curriculum. 

Built with **Clean Architecture** and **MVVM**, this project demonstrates a strict separation of concerns—isolating pure domain logic from SwiftUI views and infrastructure. The app leverages **Combine** for reactive state management, highly decoupled ViewModels, and Behavior-Driven Development (BDD) specifications to handle complex progression logic, curriculum unlocking, and sudden-death exam mechanics.

### ✨ Key Technical Highlights
- **Clean Architecture:** Complete decoupling of the Domain layer, Presentation layer (SwiftUI/Dumb Views), and Data/Infrastructure layer (Adapters).
- **Reactive MVVM:** Pure ViewModels that manage state via Combine without importing UI frameworks or directly coupling to databases.
- **Offline-First:** The entire chess curriculum and puzzle engine run locally, driven by a robust JSON data architecture.
- **Behavior-Driven (BDD):** Core progression algorithms, the "99% Rule," and sequence navigations are backed by strict BDD testing scenarios using `XCTest`.

# ♟️ Complete Architecture & Product Specification: Progressive Chess App

## Table of Contents

* [1. Product Overview & Navigation Architecture](#1-product-overview--navigation-architecture)
* [1.1 The 3-Layer UI Hierarchy](#11-the-3-layer-ui-hierarchy)
* [1.2 The 99% Progress Bar Rule](#12-the-99-progress-bar-rule)


* [2. JSON Data Architecture (Single Source of Truth)](#2-json-data-architecture-single-source-of-truth)
* [2.1 JSON Schema Structure](#21-json-schema-structure)
* [2.2 Clean Architecture: Domain vs. Presentation Models](#22-clean-architecture-domain-vs-presentation-models)


* [3. Onboarding & Placement Test Flow](#3-onboarding--placement-test-flow)
* [3.1 The Absolute Beginner Route](#31-the-absolute-beginner-route)
* [3.2 The Experienced Route (Placement Test)](#32-the-experienced-route-placement-test)


* [4. The Mix Puzzle Exam Gameplay Mechanics](#4-the-mix-puzzle-exam-gameplay-mechanics)
* [5. Behavior-Driven Development (BDD) Specifications](#5-behavior-driven-development-bdd-specifications)
* [Flow 1: Onboarding & Placement](#flow-1-onboarding--placement)
* [Flow 2: Progression & The 99% Rule](#flow-2-progression--the-99-rule)
* [Flow 3: Exam Gameplay & Penalties](#flow-3-exam-gameplay--penalties)
* [Flow 4: Sequence Navigation & Puzzle Progression (Layer 3)](#flow-4-sequence-navigation--puzzle-progression-layer-3)
* [Flow 5: Theme Customization (Board & Pieces)](#flow-5-theme-customization-board--pieces)


* [7. Core Swift Implementation (Clean Architecture)](#7-core-swift-implementation-clean-architecture)
* [7.1 Sequence Navigation Engine (PuzzleBoardViewModel)](#71-sequence-navigation-engine-puzzleboardviewmodel)
* [7.2 Exam Gameplay Engine (ExamViewModel)](#72-exam-gameplay-engine-examviewmodel)
* [7.3 Theme Customization Engine (ThemeManager)](#73-theme-customization-engine-thememanager)



---

## 1. Product Overview & Navigation Architecture

The application is a single-player, offline-first educational chess platform. It utilizes a structured, 3-layer progression system driven by a static local JSON data source. The core philosophy is to provide a linear, gamified learning path with strict mastery checkpoints.

### 1.1 The 3-Layer UI Hierarchy

* **Layer 1 (Section by Elo):** The main curriculum screen divided by rating brackets (e.g., 500-800, 800-1200). Higher sections are locked by default and strictly require passing the previous section's exam.
* **Layer 2 (Theme List):** Inside an unlocked section, users see specific tactical themes (e.g., Checkmates, Fundamental Tactics). Users can play these themes in any order. At the bottom of this list lies the Mix Puzzle Exam.
* **Layer 3 (Puzzle Board):** The actual interactive chess board where users solve specific tactical puzzles.

### 1.2 The 99% Progress Bar Rule

* Each Section and Sub-Theme has a visual progress bar.
* Completing puzzles inside standard themes updates the progress bar proportionally.
* Once all standard themes in a Section are 100% completed, the Section's overall progress bar strictly halts at **99%**.
* The remaining 1% (which acts as the trigger to unlock the next Elo Section) can only be achieved by passing the Mix Puzzle Exam.

---

## 2. JSON Data Architecture (Single Source of Truth)

To ensure maximum offline performance and simplicity, the entire curriculum is bundled into a single JSON file (`curriculum_final.json`).

### 2.1 JSON Schema Structure

The data is structured hierarchically to perfectly match the UI layers.

```json
{
  "curriculum_version": "2.0",
  "metadata": {
    "description": "Progressive Chess Curriculum with 3-Lives Exam Mechanics",
    "total_sections": 4,
    "target_puzzles_per_sub_theme": 10,
    "target_puzzles_per_exam": 100
  },
  "elo_sections": [
    {
      "section_id": "sec_500_800",
      "title": "Beginner Foundation",
      "elo_range": "500-800",
      "is_locked_by_default": false,
      "categories": [
        {
          "category_id": "cat_checkmates",
          "title": "Checkmates",
          "is_exam_mode": false,
          "sub_themes": [
            {
              "sub_theme_id": "sub_mate_1",
              "title": "Mate in 1",
              "total_puzzles": 10,
              "puzzles": [
                {
                  "id": "abc12",
                  "fen": "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 0 1",
                  "moves": ["f3f7"],
                  "rating": 600,
                  "tags": ["mateIn1", "short"]
                }
              ]
            }
          ]
        },
        {
          "category_id": "cat_exam_500_800",
          "title": "Mix Puzzle Exam",
          "is_exam_mode": true,
          "description": "Complete 10 puzzles to prove your mastery. You have 3 lives.",
          "total_puzzles": 100,
          "puzzles": [ ... 100 random puzzles ... ]
        }
      ]
    }
  ]
}

```

### 2.2 Clean Architecture: Domain vs. Presentation Models

The application employs Clean Architecture, separating pure domain data models from the reactive UI models.

```swift
import Foundation

// MARK: - 1. Pure Domain Models (Decoded from JSON)
public struct Curriculum: Codable {
    public let sections: [EloSection]
}

public struct EloSection: Codable, Identifiable {
    public let id: String
    public let title: String
    public let eloRange: String
    public let categories: [Category]
}

// MARK: - 2. Persistent State Model (User Defaults / Database)
public struct UserProgress: Codable {
    public var hiddenRating: Double
    public var completedPuzzleIDs: Set<String>
    public var passedExamIDs: Set<String>
    public var examFailureTimes: [String: Date]
}

// MARK: - 3. Presentation UI Models (Dumb Models for SwiftUI)
public struct SectionUIModel: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let progress: Double
    public let isUnlocked: Bool
    public let categories: [CategoryUIModel]
}

public struct SubThemeUIModel: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let totalPuzzles: Int
    public let completedPuzzles: Int // Dynamically calculated by ViewModel
    public let puzzles: [PuzzleUIModel]
}

```

---

## 3. Onboarding & Placement Test Flow

### 3.1 The Absolute Beginner Route

* If the user selects "I am new to chess", the placement test is skipped.
* The system assigns a base HiddenRating of 500.
* Only the "500-800" Curriculum Section is unlocked.

### 3.2 The Experienced Route (Placement Test)

* If the user selects "I have some experience", they undergo a 15-puzzle assessment.
* **NO LIVES, NO COOLDOWN:** This is an assessment, not a punishment. Users are not penalized or locked out for failing.
* **Dynamic Calibration:** The user starts at a provisional rating of 1000. Correct solves increase the rating and difficulty; incorrect solves decrease the rating and difficulty while showing the correct move.
* **Final Placement:** After 15 puzzles, the system permanently unlocks all Curriculum Sections up to that rating bracket.

---

## 4. The Mix Puzzle Exam Gameplay Mechanics

The Mix Puzzle acts as the final exam for each Elo section.

* **Bank Randomization:** The system randomly selects exactly **10 puzzles** from the category's hidden pool of 100 puzzles.
* **3-Lives Sudden Death:** The user is granted exactly 3 lives per exam attempt. Incorrect moves or tapping the "Hint" button deducts 1 life.
* **Move-On Mode:** When a life is lost, the correct move is briefly revealed, and the UI forces progression to the next puzzle.
* **3-Hour Cooldown Penalty:** If the user loses all 3 lives, the exam is marked as "Failed", displaying a strict 3-hour countdown timer based on local device time.

---

## 5. Behavior-Driven Development (BDD) Specifications

### Flow 1: Onboarding & Placement

```gherkin
Feature: User Onboarding and Dynamic Placement Test

Scenario: User declares as an absolute beginner
  Given the user is on the initial onboarding screen
  When the user selects "I am new to chess"
  Then the system assigns a hidden base rating of 500
  And the system unlocks ONLY the "500-800" Elo Section

Scenario: Placement test concludes and unlocks corresponding sections
  Given the user completes the 15th puzzle
  When the system calculates the final calibrated rating (e.g., 1350)
  Then the system unlocks all sections up to the placed bracket
```



### Flow 2: Progression & The 99% Rule

```gherkin
Feature: Curriculum Progression and The 99% Rule

Scenario: Completing all themes triggers the 99% state
  Given the user is on the Theme List
  When the user successfully completes all puzzles in all non-exam themes
  Then the Section's overall progress bar updates to exactly 99%
  And the progress bar halts
  And the Mix Puzzle Exam button state changes to "Unlocked"
```

### Flow 3: Exam Gameplay & Penalties

```gherkin
Feature: Mix Puzzle Exam Gameplay, Lives, and Cooldown

Scenario: Depleting lives triggers a 3-hour cooldown
  Given the user is taking the exam with 1 life remaining
  When the user makes a mistake or uses a hint
  Then the lives counter drops to 0
  And the exam session immediately terminates
  And the system records the current timestamp as the failure time
  And the Mix Puzzle Exam button is locked with a 3-hour countdown timer


Scenario: Passing the exam synchronizes the progression
  Given the user correctly solves the 10th puzzle with at least 1 life remaining
  Then the Section's progress bar updates from 99% to 100%
  And the next sequential Elo Section becomes unlocked
```

### Flow 4: Sequence Navigation & Puzzle Progression (Layer 3)

```gherkin
Feature: Automatic Progress Continuation and Puzzle History Navigation

Scenario 1: Automatically resuming an incomplete puzzle sequence (Resume Progress)
  Given the user has completed for instance 5 out of 10 puzzles in the "Checkmates" theme
  When the user exits the puzzle board and re-enters the "Checkmates" theme later
  Then the system must detect that the 6th puzzle is the ongoing (unsolved) sequence
  And the system must automatically load and present the 6th puzzle


Scenario 2: Restricting the sequence popup list to unlocked puzzles
  Given the user is currently on the 6th puzzle (ongoing)
  When the user taps the "Sequence List" button
  Then the popup must only display options from Puzzle 1 to Puzzle 6 as selectable
  And options from Puzzle 7 to Puzzle 10 must be hidden or visually locked


Scenario 3: Returning to the main progression after reviewing an old puzzle
  Given the user has an active progression frontier at Puzzle 6
  And the user opens the sequence list and chooses to replay the completed Puzzle 3
  When the user successfully solves Puzzle 3 again
  Then the system detects that Puzzle 3 was already completed
  And when the user taps "Next", the system automatically skips intermediate puzzles and routes directly back to the frontier (Puzzle 6)


Scenario 4: Initial entry behavior for a 100% completed theme
  Given the user has successfully completed all 10 puzzles in a theme
  When the user taps the theme from Layer 3
  Then the system must load and present Puzzle 1 by default
  And all sequence options from Puzzle 1 to Puzzle 10 must be unlocked


Scenario 5: Linear progression from a free choice in a completed theme
  Given the user is inside a theme that is 100% completed
  And the user utilizes the sequence list to jump directly to Puzzle 6
  When the user successfully solves Puzzle 6
  Then the system must linearly route the user to the next puzzle (Puzzle 7)
```

### Flow 5: Theme Customization (Board & Pieces)

```gherkin
Feature: Chess Board and Piece Theme Customization

Scenario 1: Changing the board theme
  Given the user is on the Theme Settings page
  When the user selects the "Green" board theme
  Then the board's dark and light squares change to green-themed colors
  And the board highlight color remains strictly mapped to "#2596be"


Scenario 2: Theme persistence across sessions
  Given the user has selected a custom piece style and board theme
  When the user completely closes and reopens the application
  Then the system retrieves the saved preferences from UserDefaults (AppStorage)
  And the application successfully reapplies the themes to the chess board
```

---

## 7. Core Swift Implementation (Clean Architecture)

The application avoids `UserDefaults` in the core domain logic. State and side effects are managed through pure `ViewModels` and delegated to infrastructure via callback functions in the `AppComposer`.

### 7.1 Sequence Navigation Engine (`PuzzleBoardViewModel`)

Handles scenarios 1 through 5 for puzzle progression mapping.

```swift
import Foundation
import Combine
import EssentialChess

public final class PuzzleBoardViewModel: ObservableObject, Identifiable {

    @Published public var currentActiveIndex: Int = 0
    @Published public var isSolved: Bool = false
    @Published public var wrongAttempts: Int = 0
    @Published public var isSessionComplete: Bool = false

    public let puzzles: [Puzzle]
    private var completedPuzzleIDs: Set<String>

    // Callback to AppComposer to handle persistence
    private let onPuzzleSolved: (String) -> Void

    public init(puzzles: [Puzzle], initialCompletedIDs: Set<String>, onPuzzleSolved: @escaping (String) -> Void) {
        self.puzzles = puzzles
        self.completedPuzzleIDs = initialCompletedIDs
        self.onPuzzleSolved = onPuzzleSolved

        let themeFullyCompleted = !puzzles.isEmpty && puzzles.allSatisfy { initialCompletedIDs.contains($0.id) }
        let frontierIndex = puzzles.firstIndex { !initialCompletedIDs.contains($0.id) } ?? 0

        // Scenario 1 & 4 implementation
        self.currentActiveIndex = themeFullyCompleted ? 0 : frontierIndex
    }

    public var currentPuzzle: Puzzle? {
        guard currentActiveIndex < puzzles.count else { return nil }
        return puzzles[currentActiveIndex]
    }

    public var unlockedCount: Int {
        isThemeFullyCompleted ? puzzles.count : min(highestUnsolvedIndex + 1, puzzles.count)
    }

    private var highestUnsolvedIndex: Int {
        puzzles.firstIndex { !completedPuzzleIDs.contains($0.id) } ?? 0
    }

    private var isThemeFullyCompleted: Bool {
        !puzzles.isEmpty && puzzles.allSatisfy { completedPuzzleIDs.contains($0.id) }
    }

    public func isCompleted(_ puzzle: Puzzle) -> Bool {
        completedPuzzleIDs.contains(puzzle.id)
    }

    public func triggerNext() {
        if isThemeFullyCompleted {
            // Scenario 5: Linear progression through a completed theme
            if currentActiveIndex < puzzles.count - 1 {
                currentActiveIndex += 1
                reset()
            } else {
                isSessionComplete = true
            }
        } else {
            // Scenario 3: Always jump back to the progression frontier
            let next = highestUnsolvedIndex
            if next >= puzzles.count {
                isSessionComplete = true
            } else {
                currentActiveIndex = next
                reset()
            }
        }
    }

    public func markSolved() {
        guard let puzzle = currentPuzzle, !isSolved else { return }
        isSolved = true
        completedPuzzleIDs.insert(puzzle.id)
        onPuzzleSolved(puzzle.id) // Notify infrastructure
    }

    public func jumpTo(index: Int) {
        guard index < unlockedCount else { return }
        currentActiveIndex = index
        reset()
    }

    private func reset() {
        isSolved = false
        wrongAttempts = 0
    }
}

```

### 7.2 Exam Gameplay Engine (`ExamViewModel`)

Handles 3-lives sudden death without depending on `ProgressStore`.

```swift
import Foundation
import Combine
import EssentialChess

public final class ExamViewModel: ObservableObject {
    public enum ExamPhase { case active, passed, failed }

    @Published public private(set) var remainingLives: Int = 3
    @Published public private(set) var solvedCount: Int = 0
    @Published public private(set) var currentIndex: Int = 0
    @Published public private(set) var phase: ExamPhase = .active

    public let puzzles: [Puzzle]
    private let onPassed: () -> Void
    private let onFailed: () -> Void

    public init(puzzles: [Puzzle], onPassed: @escaping () -> Void, onFailed: @escaping () -> Void) {
        self.puzzles = puzzles
        self.onPassed = onPassed
        self.onFailed = onFailed
    }

    public var currentPuzzle: Puzzle? {
        guard currentIndex < puzzles.count else { return nil }
        return puzzles[currentIndex]
    }

    public var totalPuzzles: Int { puzzles.count }

    public func handleCorrect() {
        guard phase == .active else { return }
        solvedCount += 1
        currentIndex += 1
        if currentIndex >= puzzles.count {
            phase = .passed
            onPassed()
        }
    }

    public func handleIncorrect() {
        guard phase == .active else { return }
        remainingLives -= 1
        if remainingLives <= 0 {
            phase = .failed
            onFailed()
        }
    }

    public func skipPuzzle() {
        guard phase == .active else { return }
        currentIndex += 1
        if currentIndex >= puzzles.count {
            phase = .failed
            onFailed()
        }
    }
}

```

### 7.3 Theme Customization Engine (`ThemeManager`)

Handles UI customization preferences using standard `AppStorage` logic.

```swift
import SwiftUI
import Combine

public enum BoardThemeOption: String, CaseIterable {
    case brown = "Brown"
    case green = "Green"
    case blue = "Blue"

    public var lightSquareColor: UIColor {
        switch self {
        case .brown: return UIColor(red: 0.94, green: 0.85, blue: 0.71, alpha: 1.0)
        case .green: return UIColor(red: 0.93, green: 0.93, blue: 0.82, alpha: 1.0)
        case .blue:  return UIColor(red: 0.89, green: 0.93, blue: 0.96, alpha: 1.0)
        }
    }

    public var darkSquareColor: UIColor {
        switch self {
        case .brown: return UIColor(red: 0.71, green: 0.53, blue: 0.39, alpha: 1.0)
        case .green: return UIColor(red: 0.46, green: 0.59, blue: 0.34, alpha: 1.0)
        case .blue:  return UIColor(red: 0.43, green: 0.58, blue: 0.73, alpha: 1.0)
        }
    }

    public var highlightColor: UIColor {
        return UIColor(red: 0.145, green: 0.588, blue: 0.745, alpha: 1.0) // #2596be
    }
}

public class ThemeManager: ObservableObject {
    @AppStorage("selected_board_theme") private var savedBoardThemeString: String = BoardThemeOption.brown.rawValue
    @AppStorage("selected_piece_theme") private var savedPieceThemeString: String = "default"

    @Published public var currentBoardTheme: BoardThemeOption {
        didSet { savedBoardThemeString = currentBoardTheme.rawValue }
    }

    @Published public var currentPieceTheme: String {
        didSet { savedPieceThemeString = currentPieceTheme }
    }

    public init() {
        self.currentBoardTheme = BoardThemeOption(rawValue: UserDefaults.standard.string(forKey: "selected_board_theme") ?? "") ?? .brown
        self.currentPieceTheme = UserDefaults.standard.string(forKey: "selected_piece_theme") ?? "default"
    }
}

```
