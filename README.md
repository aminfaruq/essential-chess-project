<p align="center">
  <img src="EssentialChessApp/essential_chess_demo.gif" width="250" alt="Essential Chess Demo">
</p>

# ♟️ Essential Chess

A structured, offline-first chess tactics trainer for iOS.

![Swift](https://img.shields.io/badge/Swift-5.9+-orange?style=flat-square&logo=swift)
![iOS](https://img.shields.io/badge/iOS-16.0+-black?style=flat-square&logo=apple)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture%20%7C%20MVVM-blue?style=flat-square)
![Framework](https://img.shields.io/badge/Framework-SwiftUI%20%7C%20Combine-blueviolet?style=flat-square)

Essential Chess replaces the typical random-puzzle approach with a mastery-based Elo curriculum. Users progress through structured sections, pass high-stakes exams to advance, and train in endless adaptive modes — all running entirely offline from bundled JSON data.

---

## Engineering Highlights

- **Three-target modular architecture** — `EssentialChess` (domain + infrastructure), `EssentialChessUI` (framework-free ViewModels), `EssentialChessApp` (SwiftUI composition root). Domain and presentation targets have zero UIKit/SwiftUI imports.
- **All ViewModels tested for memory leaks** — every `makeSUT()` factory in test suites calls `trackForMemoryLeaks()` via `addTeardownBlock` to catch retain cycles automatically.
- **Elo rating engine** — standard expected-score formula with separate K-factors for placement (K=100) and regular play (K=32), floor-clamped at 100.
- **iCloud sync with local fallback** — `UbiquitousProgressStore` reads from `NSUbiquitousKeyValueStore`, auto-migrates existing `UserDefaults` data on first launch, and listens for `didChangeExternallyNotification` for cross-device sync.
- **Native UIKit chess board** via `ChessBoard` package, bridged into SwiftUI through `UIViewRepresentable` with `Equatable` conformance to prevent unnecessary redraws.

---

## Table of Contents

1. [App Features](#1-app-features)
2. [Architecture](#2-architecture)
3. [Testing](#3-testing)
4. [Known Limitations & Roadmap](#4-known-limitations--roadmap)

---

## 1. App Features

### Curriculum (3-Layer Hierarchy)

| Layer | What the user sees |
|---|---|
| **Section** | Elo rating brackets (e.g., 500–800, 800–1200). Locked by default; unlocked when `hiddenRating >= eloFloor` or the previous section's exam is passed. |
| **Category / Theme** | Tactical themes within a section (e.g., "Checkmates", "Fundamental Tactics"), each containing sub-themes with individual progress bars. |
| **Puzzle Board** | Interactive board powered by the `ChessBoard` UIKit package. Supports FEN-based puzzle loading, move validation, hints, haptic feedback, and sound effects. |

### The 99% Rule

Section progress is computed by `CurriculumProgressCalculator.progress(for:progress:)`. When all non-exam puzzles in a section are completed, progress caps at exactly `0.99` via `min(0.99, completedRatio)`. The final 1% requires passing the section's Mix Puzzle Exam. This is enforced in code and verified by `test_progress_capsAt99PercentIfExamNotPassed`.

### Mix Puzzle Exam

Each section has one exam category (`isExamMode = true`). The exam engine (`ExamViewModel`) works as follows:

- **Bank:** Up to 10 puzzles randomly selected from the exam's pool (`Array(examPuzzles.shuffled().prefix(10))`).
- **3-lives sudden death:** Incorrect moves and hints each call `loseLife()`. At 0 lives → `phase = .failed`, `onFailed()` callback fires. Passing all puzzles → `phase = .passed`, `onPassed()` fires.
- **3-hour cooldown:** On failure, `examFailureTimes[categoryID] = Date()` is persisted. `canStartExam()` checks `currentDate.timeIntervalSince(failTime) >= 10800`.

### Puzzle Mix (Endless Adaptive Mode)

`PuzzleMixViewModel` provides an endless stream of puzzles matched to the user's `actualRating`:

- **Puzzle selection:** Filters the bundled pool for puzzles within ±150 of `actualRating`. Falls back to the closest-rated unused puzzle, then cycles the entire pool if exhausted.
- **Rating initialization:** On first open, `actualRating` is initialized from `hiddenRating` and persisted immediately.
- **Rating updates:** Uses `RatingCalculator.calculateRegularRating()` (K=32 Elo formula). Using a hint triggers `decreaseRating()`, which scores as an incorrect solve.

### Puzzle Streak (Survival Mode)

`PuzzleStreakViewModel` implements a survival mode where one mistake ends the run:

- **Scaling difficulty:** Target rating starts at 500 and increases by 50 per correct solve (`500 + (currentStreak * 50)`), with a ±100 tolerance window.
- **Session persistence:** Active streak count and used puzzle IDs are persisted to `UserProgress` after each puzzle, enabling resume across app launches.
- **Records:** `highestPuzzleStreak` is tracked and updated on session end if the current run exceeds it.

### Onboarding & Placement Test

`OnboardingViewModel` handles two paths:

- **Beginner:** Sets `hiddenRating = 500`, marks `onboardingComplete = true`, unlocks only the first section.
- **Experienced:** 15-puzzle adaptive assessment starting at rating 1000. Uses `RatingCalculator.calculatePlacementRating()` (K=100) for faster calibration. Final rating unlocks all sections up to that Elo bracket.

### Daily Streak

`UserProgress.recordActivity()` implements consecutive-day tracking:

- First activity ever → streak = 1.
- Same day → no change to streak count.
- Next consecutive day → streak + 1.
- Gap of 2+ days → streak resets to 1.

`StreakViewModel` subscribes to the progress publisher and exposes `streakCount` and `isStreakActiveToday` for the UI flame indicator.

### Settings & Customization

Managed by `SettingsViewModel` through protocol-based storage:

**Appearance** (persisted via `ThemeLoader` in UserDefaults)
- Board themes: Brown, Green, Blue, Monochrome
- Piece styles: Standard, Alpha, Fantasy
- Theme values are pure `RGBAColor` structs defined in the domain layer — zero UIKit/SwiftUI coupling

**Board behaviour** (persisted via `BoardSettingsStore`)
- Haptic feedback toggle → `PuzzleChessBoardView.setHapticEnabled()`
- Sound effects toggle → `PuzzleChessBoardView.setSoundEnabled()`

**Notifications** (persisted via `NotificationStore`, scheduled by `NotificationSchedulerLoader`)
- Daily reminder at 08:00 via `UNCalendarNotificationTrigger`
- Tapping notification deep-links to Puzzle tab via `NotificationCenter`

**Language** (persisted via `LanguageStore`)
- English and Bahasa Indonesia, applied via `.environment(\.locale)`

**Reset progress** (via `ProgressAdapter.update`)
- Clears puzzle IDs, exam IDs, failure times, sets `onboardingComplete = false`

---

## 2. Architecture

### Module Structure

```
EssentialChess/                     ← Xcode project with 4 targets
├── EssentialChess/                 ← Domain + Infrastructure framework
│   ├── Domain/
│   │   ├── Models/                 ← Curriculum, UserProgress, MixPool, ThemeSettings, etc.
│   │   ├── Protocols/              ← ProgressLoader, ThemeLoader, CurriculumLoader, etc.
│   │   └── UseCases/               ← CurriculumProgressCalculator, RatingCalculator, ECODetector, etc.
│   └── Infrastructure/
│       ├── Adapters/               ← ProgressAdapter, ThemeAdapter, LanguageAdapter, Combine bridges
│       ├── Loaders/                ← FileCurriculumLoader, FileMixPoolLoader, FileECOLoader, CloudEvaluation
│       ├── Networking/             ← LocalFileReader, URLSessionHTTPClient
│       └── Persistence/            ← UserDefaultsProgressLoader, UbiquitousProgressStore, theme/board/notification/tab stores
├── EssentialChessUI/               ← Presentation framework (ViewModels only)
│   └── ViewModels/                 ← 13 ViewModels in Curriculum/, Exam/, Onboarding/, Opening/, Puzzle/, Settings/
├── EssentialChessTests/            ← Domain + Infrastructure tests
└── EssentialChessUITests/          ← ViewModel tests

EssentialChessApp/                  ← iOS app target (composition root)
├── AppCore/                        ← AppComposer, DependencyContainer, ViewFactory, EnvironmentConfig, RootView
├── DesignSystem/                   ← AppColors, ProgressBarView, PuzzleTagFormatter, StreakView
├── Views/                          ← SwiftUI views (Curriculum, Exam, Puzzle, Settings, Onboarding)
├── EssentialChessAppTests/         ← Integration tests
└── EssentialChessAppUITests/       ← UI tests

ChessBoard/                         ← UIKit chess board package
├── ChessBoard/                     ← ChessEngine, PuzzleValidator, BoardGeometry, iOS board views
└── ChessBoardTests/                ← Engine, validator, geometry tests
```

### Dependency Direction

```
EssentialChessApp → EssentialChessUI → EssentialChess
                   → ChessBoard (UIKit chess board package)
```

The domain layer (`Domain/Protocols/`) defines protocols (`ProgressLoader`, `ThemeLoader`, `CurriculumLoader`, `NotificationSchedulerLoader`, etc.). Infrastructure implementations conform to these protocols. ViewModels depend only on domain types and Combine — they never import SwiftUI or UIKit.

### Dependency Injection

Dependencies flow through `DependencyContainer` → `AppComposer` → `ViewFactory`.

- `DependencyContainer` instantiates all infrastructure (stores, adapters, loaders) and owns their lifecycle.
- `AppComposer` creates the long-lived ViewModels (`CurriculumViewModel`, `StreakViewModel`, `SettingsViewModel`, `TabNavigationViewModel`) and wires them to adapter publishers.
- `ViewFactory` creates screen-specific ViewModels on demand (exam sessions, puzzle mix, puzzle streak, onboarding) using closure-based callback injection to avoid coupling ViewModels to the persistence layer.

ViewModels receive side-effect closures (e.g., `saveActualRating: (Double) -> Void`, `onPuzzleSolved: () -> Void`) rather than direct adapter references. This keeps them unit-testable with simple mock closures.

### Persistence

| Data | Storage | Mechanism |
|---|---|---|
| User progress | `NSUbiquitousKeyValueStore` (primary), `UserDefaults` (fallback) | JSON-encoded `ProgressCacheDTO` with backward-compatible optional fields. Auto-migration from UserDefaults on first iCloud read. |
| Theme settings | `UserDefaults` | JSON-encoded `ThemeSettings` via `UserDefaultsThemeStore`. |
| Board settings | `UserDefaults` | Direct key-value via `UserDefaultsBoardSettingsStore`. |
| Tab state | `UserDefaults` | Persisted via `UserDefaultsTabStore` so the app reopens on the last-used tab. |
| Notification prefs | `UserDefaults` | `isDailyReminderEnabled` flag via `UserDefaultsNotificationStore`. |

Both `ProgressLoader` implementations use a shared `KeyValueStore` protocol that both `UserDefaults` and `NSUbiquitousKeyValueStore` conform to via extensions — allowing the `MockKeyValueStore` in tests to substitute either.

### Data Loading

The curriculum (~844KB) and mix pool (~8MB) are bundled JSON files, loaded via `FileCurriculumLoader` and `FileMixPoolLoader` respectively. Each uses a `FileReaderLoader` protocol (implemented by `LocalFileReader`) and a private `Mapper` class that keeps `Decodable` DTOs with `snake_case` keys encapsulated — domain models are never `Codable`.

Loaders expose a callback-based API (`CurriculumLoader` protocol) and are bridged to Combine publishers via `Deferred { Future { } }` extensions for use in `CurriculumViewModel`.

---

## 3. Testing

### Test Targets & Coverage

The project has 3 test targets with 42 test files covering domain logic, infrastructure, and ViewModels:

**`EssentialChessTests`** — Domain & Infrastructure (28 test files):

| Area | File | What it covers |
|---|---|---|
| Progress | `CurriculumProgressCalculatorTests` | Section unlock logic, sub-theme/category/section progress calculation, 99% cap rule, exam unlock gate, 3-hour cooldown enforcement |
| Progress | `UserProgressUpdaterTests` | Immutable progress mutations (complete onboarding, mark puzzle, pass/fail exam, reset) |
| Progress | `UserProgressDailyStreakTests` | Streak increment on consecutive day, no-change on same day, reset on missed day, first-time initialization |
| Rating | `RatingCalculatorTests` | Placement K=100 and regular K=32 calculations, minimum rating floor (100), bracket assignment |
| ECO | `ECODetectorTests` | Opening code detection from move sequences |
| Beginner | `BeginnerProgressStoreTests` | Beginner progress persistence |
| Theme | `ThemeSettingsTests` | Theme settings encode/decode |
| Curriculum | `FileCurriculumLoaderTests` | JSON loading, mapper validation, error handling for invalid data |
| Mix Pool | `FileMixPoolLoaderTests` | JSON loading, difficulty tier mapping, error handling |
| ECO | `FileECOLoaderTests` | ECO data loading and mapping |
| Cloud | `CloudEvaluationMapperTests`, `RemoteCloudEvaluationLoaderTests` | Lichess cloud eval parsing, HTTP integration |
| Cache | `UserDefaultsProgressStoreTests` | Round-trip encode/decode of `UserProgress` through `ProgressCacheDTO` |
| Cache | `UbiquitousProgressStoreTests` | iCloud store read/write, UserDefaults→iCloud migration, backward-compatible optional field decoding |
| Cache | `UserDefaultsThemeStoreTests` | Theme settings persistence |
| Cache | `UserDefaultsBoardSettingsStoreTests` | Board settings persistence |
| Cache | `UserDefaultsLanguageStoreTests` | Language preference persistence |
| Cache | `UserDefaultsNotificationStoreTests` | Notification preference persistence |
| Cache | `UserDefaultsTabStoreTests` | Tab state persistence |
| Networking | `LocalFileReaderTests` | File reading from disk |
| Networking | `URLSessionHTTPClientTests` | HTTP client with header/callback verification |
| Adapters | `ProgressAdapterTests`, `ThemeAdapterTests`, `LanguageAdapterTests`, `UserNotificationsAdapterTests` | Adapter state management, publisher emissions |
| Adapters | `CurriculumLoaderCombineTests`, `MixPoolLoaderCombineTests` | Combine publisher bridge from callback-based loaders |

**`EssentialChessUITests`** — ViewModel Logic (13 test files):

| ViewModel | Key scenarios tested |
|---|---|
| `BeginnerCurriculumViewModelTests` | Beginner puzzle session flow, piece learning progression |
| `CurriculumViewModelTests` | Section/category mapping, section lock logic, exam state mapping |
| `PuzzleBoardViewModelTests` | Linear puzzle progression, frontier-based navigation, theme completion detection |
| `ExamViewModelTests` | Initial state, correct/incorrect handling, hint costs life, 3-life depletion triggers `onFailed`, all-solved triggers `onPassed` |
| `PuzzleMixViewModelTests` | `actualRating` initialization from `hiddenRating`, ±150 range filtering, rating increase/decrease on solve, hint-as-failure, pool cycling on exhaustion |
| `PuzzleStreakViewModelTests` | Streak increment, failure ends session, new-record detection |
| `PuzzleStormViewModelTests` | Timer-based storm mode mechanics |
| `OnboardingViewModelTests` | 15-puzzle assessment flow, rating calibration, completion callback |
| `OpeningRecognitionViewModelTests` | Opening detection from FEN/move sequences |
| `SettingsViewModelTests` | Haptic/sound toggle persistence, notification scheduling, permission handling |
| `StreakViewModelTests` | Publisher-driven streak count updates, "active today" detection |
| `TabNavigationViewModelTest` | Tab persistence, auto-save on change |
| `PuzzleViewModelTests` | Solve/wrong state management, hint delegation |

**`EssentialChessAppTests`** — Composition root integration tests.

All ViewModel tests use a shared `trackForMemoryLeaks()` helper in `addTeardownBlock` to catch retain cycles.

### BDD-Style Specifications

Core algorithms are expressed as Given/When/Then scenarios. Each scenario below has a corresponding `XCTest`:

#### Curriculum Progress & Exam Gating

```gherkin
Feature: Section Progress and the 99% Rule

  Scenario: Progress caps at 99% when all puzzles complete but exam not passed
    Given a section with 2 non-exam puzzles
    When the user completes both puzzles
    Then section progress equals 0.99 via CurriculumProgressCalculator

  Scenario: Progress reaches 100% after exam is passed
    Given a section with a passed exam ID in the user's progress
    Then section progress equals 1.0 via CurriculumProgressCalculator

  Scenario: Exam unlocks only when all non-exam puzzles are completed
    Given 2 puzzles in non-exam categories
    When only 1 is completed
    Then isExamUnlocked returns false
    When both are completed
    Then isExamUnlocked returns true
```

#### Exam Gameplay

```gherkin
Feature: Mix Puzzle Exam — 3-Lives Sudden Death

  Scenario: Depleting lives triggers failure callback
    Given an active exam with 3 lives
    When the user makes 3 incorrect moves
    Then phase transitions to .failed
    And onFailed is called exactly once

  Scenario: Completing all puzzles triggers pass callback
    Given an exam with 1 puzzle
    When the user answers correctly
    Then phase transitions to .passed
    And onPassed is called exactly once

  Scenario: Using a hint costs a life
    Given an active exam with 3 lives
    When the user taps Hint
    Then remaining lives decreases to 2
```

#### Exam Cooldown

```gherkin
Feature: 3-Hour Exam Cooldown

  Scenario: Cannot retake exam within cooldown window
    Given an exam failed at time T
    When current time is T + 2 hours
    Then canStartExam returns false

  Scenario: Can retake exam after cooldown expires
    Given an exam failed at time T
    When current time is T + 3 hours
    Then canStartExam returns true
```

#### Puzzle Mix — Rating

```gherkin
Feature: Endless Puzzle Mix

  Scenario: First-time rating initialization
    Given hiddenRating is 1350 and actualRating is nil
    When PuzzleMixViewModel is initialized
    Then actualRating equals 1350
    And the rating is saved immediately

  Scenario: Correct solve increases rating
    Given actualRating is 1200 and puzzle rating is 1200
    When the user solves correctly
    Then actualRating increases (K=32 Elo)
    And the updated rating is persisted

  Scenario: Hint usage penalizes rating
    Given an active puzzle
    When the user taps Hint
    Then actualRating decreases as if the solve were incorrect
    And hasUsedHint is set to true
```

#### Daily Streak

```gherkin
Feature: Daily Activity Streak

  Scenario: First-time play sets streak to 1
    Given no previous activity
    When the user completes a puzzle
    Then currentStreak equals 1

  Scenario: Playing on the next consecutive day increments streak
    Given last activity was yesterday and streak is 3
    When the user plays today
    Then currentStreak equals 4

  Scenario: Missing a day resets streak
    Given last activity was 2 days ago and streak is 5
    When the user plays today
    Then currentStreak resets to 1
```

---

## 4. Known Limitations & Roadmap

### Current Limitations

| Item | Status |
|---|---|
| **Accessibility** | Not explicitly implemented beyond standard SwiftUI defaults. |
| **macOS Catalyst** | Intentionally disabled (`SUPPORTS_MACCATALYST = NO`). A native macOS version with expanded features is planned. |

### Roadmap

| Feature | Platform | Status |
|---|---|---|
| **Chess Analysis** | iOS, macOS | Next implementation. Cloud engine evaluation via Lichess API + local Stockfish engine. |
| **Opening Training** | iOS, macOS | Planned. Structured opening repertoire drilling with spaced repetition. |
| **Matchmaking** | macOS | Planned. Player-vs-player matchmaking via Lichess API. |
| **Chess Database Management** | macOS | Planned. Browse, search, and analyze master games. |
| **Native macOS App** | macOS | Planned. Full-featured native Mac app with all iOS features plus Mac-exclusive additions above. |

---

## Screenshots & Demo

> \[TODO: Add App Store screenshots and demo video after release\]

---

## License

See [LICENSE](LICENSE) for details.
