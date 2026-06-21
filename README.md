<p align="center">
  <img src="EssentialChessApp/essential_chess_demo.gif" width="250" alt="Essential Chess Demo">
</p>

# ♟️ Essential Chess

A structured, offline-first chess tactics trainer for iOS and macOS Catalyst.

![Swift](https://img.shields.io/badge/Swift-5.9+-orange?style=flat-square&logo=swift)
![iOS](https://img.shields.io/badge/iOS-16.0+-black?style=flat-square&logo=apple)
![macOS](https://img.shields.io/badge/macOS%20Catalyst-Supported-blue?style=flat-square&logo=apple)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture%20%7C%20MVVM-blue?style=flat-square)
![Framework](https://img.shields.io/badge/Framework-SwiftUI%20%7C%20Combine-blueviolet?style=flat-square)

Essential Chess replaces the typical random-puzzle approach with a mastery-based Elo curriculum. Users progress through structured sections, pass high-stakes exams to advance, and train in endless adaptive modes — all running entirely offline from bundled JSON data.

> **Status:** Pre-release. Paywall is implemented as a UI shell (purchase sets `isPro = true` locally); RevenueCat integration is pending. Puzzle Storm mode has a placeholder view.

---

## Engineering Highlights

- **Three-target modular architecture** — `EssentialChess` (pure domain), `EssentialChessUI` (framework-free ViewModels), `EssentialChessApp` (SwiftUI composition root). Domain and presentation targets have zero UIKit/SwiftUI imports.
- **All ViewModels tested for memory leaks** — every `makeSUT()` factory in test suites calls `trackForMemoryLeaks()` via `addTeardownBlock` to catch retain cycles automatically.
- **Elo rating engine** — standard expected-score formula with separate K-factors for placement (K=100) and regular play (K=32), floor-clamped at 100.
- **iCloud sync with local fallback** — `UbiquitousProgressStore` reads from `NSUbiquitousKeyValueStore`, auto-migrates existing `UserDefaults` data on first launch, and listens for `didChangeExternallyNotification` for cross-device sync.
- **Native UIKit chess board** via `NativeChessBoard` package, bridged into SwiftUI through `UIViewRepresentable` with `Equatable` conformance to prevent unnecessary redraws.

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
| **Section** | Elo rating brackets (e.g., 500–800, 800–1200). Locked by default; unlocked when `hiddenRating >= eloFloor` or the previous section's exam is passed. Sections beyond the first are gated behind the Pro paywall for free users. |
| **Category / Theme** | Tactical themes within a section (e.g., "Checkmates", "Fundamental Tactics"), each containing sub-themes with individual progress bars. |
| **Puzzle Board** | Interactive board powered by the `NativeChessBoard` UIKit package. Supports FEN-based puzzle loading, move validation, hints, haptic feedback, and sound effects. |

### The 99% Rule

Section progress is computed by `CurriculumProgressTracker.progress(for:progress:)`. When all non-exam puzzles in a section are completed, progress caps at exactly `0.99` via `min(0.99, completedRatio)`. The final 1% requires passing the section's Mix Puzzle Exam. This is enforced in code and verified by `test_progressForSection_capsAt99PercentIfExamNotPassed`.

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
- **Daily limit:** Free users are capped at 7 puzzles per day. Tracked via `dailyPuzzleMixCount` and `lastPuzzleMixDate` on `UserProgress`, reset on day change.

### Puzzle Streak (Survival Mode)

`PuzzleStreakViewModel` implements a survival mode where one mistake ends the run:

- **Scaling difficulty:** Target rating starts at 500 and increases by 50 per correct solve (`500 + (currentStreak * 50)`), with a ±100 tolerance window.
- **Session persistence:** Active streak count and used puzzle IDs are persisted to `UserProgress` after each puzzle, enabling resume across app launches.
- **Records:** `highestPuzzleStreak` is tracked and updated on session end if the current run exceeds it.
- **Daily limit:** Free users get 1 streak session per day.

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

Managed by `SettingsViewModel` through protocol-based storage ports:

| Setting | Storage | Details |
|---|---|---|
| Board theme | `ThemeStore` (UserDefaults) | Brown (free), Green, Blue, Monochrome (Pro). Pure `RGBAColor` values defined in domain layer, not coupled to UIKit/SwiftUI color types. |
| Piece style | `ThemeStore` (UserDefaults) | Standard (free), Alpha, Fantasy (Pro). |
| Haptic feedback | `BoardSettingsStoragePort` | Toggle, passed through to `NativeChessBoardView.setHapticEnabled()`. |
| Sound effects | `BoardSettingsStoragePort` | Toggle, passed through to `NativeChessBoardView.setSoundEnabled()`. |
| Daily reminder | `NotificationStoragePort` + `NotificationScheduler` | Schedules a `UNCalendarNotificationTrigger` at 08:00 daily. Tapping the notification deep-links to the Puzzle tab via `NotificationCenter`. |
| Language | `LanguageStoragePort` | English and Bahasa Indonesia. Applied via `.environment(\.locale)`. |
| Reset progress | Direct `ProgressAdapter.update` | Clears puzzle IDs, exam IDs, failure times, and sets `onboardingComplete = false`. |

### Freemium Model

`isPro` flag on `UserProgress` gates: curriculum sections beyond section 1, non-default themes and piece styles, unlimited Puzzle Mix (>7/day), and unlimited Puzzle Streak (>1 session/day). The Paywall UI is implemented; actual StoreKit/RevenueCat integration is pending (currently sets `isPro = true` in-memory).

---

## 2. Architecture

### Module Structure

```
EssentialChess/                     ← Xcode project with 4 targets
├── EssentialChess/                 ← Domain + Infrastructure framework
│   ├── Chess Feature/              ← Pure domain models, protocols, business logic
│   │   ├── Curriculum/             ← Curriculum, EloSection, Category, SubTheme, Puzzle
│   │   ├── Progress/               ← UserProgress, CurriculumProgressTracker, ProgressStore protocol
│   │   ├── Rating Calculator/      ← RatingCalculator (Elo formula)
│   │   ├── Mix Pool/               ← MixPool, MixPoolLoader protocol
│   │   ├── Theme/                  ← ThemeSettings, BoardThemeOption, ThemeStore protocol
│   │   ├── Settings/               ← BoardSettingsStoragePort protocol
│   │   ├── Notifications/          ← NotificationScheduler, NotificationStoragePort protocols
│   │   ├── Language/               ← LanguageStoragePort protocol
│   │   └── Tabbar/                 ← AppTab enum, TabStoragePort protocol
│   ├── Chess Cache/                ← Persistence implementations
│   │   ├── Progress/               ← UserDefaultsProgressStore, UbiquitousProgressStore, KeyValueStore
│   │   └── Theme/                  ← UserDefaultsThemeStore
│   └── Chess Infra/                ← Adapters, mappers, loaders
│       ├── Adapters/               ← ProgressAdapter, ThemeAdapter, LanguageAdapter, etc.
│       ├── Curriculum/             ← FileCurriculumLoader, CurriculumMapper (private DTOs)
│       ├── Mix Pool/               ← FileMixPoolLoader, MixPoolMapper
│       ├── Shared/                 ← LocalFileReader, FileReaderLoader protocol
│       └── Tabbar/                 ← UserDefaultsTabAdapter
├── EssentialChessUI/               ← Presentation framework (ViewModels only)
│   └── ViewModels/                 ← 10 ViewModels, all import Foundation + Combine only
├── EssentialChessTests/            ← Domain + Infrastructure tests
└── EssentialChessUITests/          ← ViewModel tests

EssentialChessApp/                  ← iOS app target (composition root)
├── AppCore/                        ← AppComposer, DependencyContainer, ViewFactory, RootView
├── Views/                          ← SwiftUI views (Curriculum, Exam, PuzzleMix, etc.)
└── EssentialChessAppTests/         ← Integration tests
```

### Dependency Direction

```
EssentialChessApp → EssentialChessUI → EssentialChess
                  → NativeChessBoard (UIKit chess board package)
```

The domain layer (`Chess Feature/`) defines protocols (`ProgressStore`, `ThemeStore`, `CurriculumLoader`, `NotificationScheduler`, etc.). Infrastructure implementations conform to these protocols. ViewModels depend only on domain types and Combine — they never import SwiftUI or UIKit.

### Dependency Injection

Dependencies flow through `DependencyContainer` → `AppComposer` → `ViewFactory`.

- `DependencyContainer` instantiates all infrastructure (stores, adapters, loaders) and owns their lifecycle.
- `AppComposer` creates the long-lived ViewModels (`CurriculumViewModel`, `StreakViewModel`, `SettingsViewModel`, `MainNavigationViewModel`) and wires them to adapter publishers.
- `ViewFactory` creates screen-specific ViewModels on demand (exam sessions, puzzle mix, puzzle streak, onboarding) using closure-based callback injection to avoid coupling ViewModels to the persistence layer.

ViewModels receive side-effect closures (e.g., `saveActualRating: (Double) -> Void`, `onPuzzleSolved: () -> Void`) rather than direct adapter references. This keeps them unit-testable with simple mock closures.

### Persistence

| Data | Storage | Mechanism |
|---|---|---|
| User progress | `NSUbiquitousKeyValueStore` (primary), `UserDefaults` (fallback) | JSON-encoded `ProgressCacheDTO` with backward-compatible optional fields. Auto-migration from UserDefaults on first iCloud read. |
| Theme settings | `UserDefaults` | JSON-encoded `ThemeSettings` via `UserDefaultsThemeStore`. |
| Board settings | `UserDefaults` | Direct key-value via `UserDefaultsBoardSettingsStorage`. |
| Tab state | `UserDefaults` | Persisted via `UserDefaultsTabAdapter` so the app reopens on the last-used tab. |
| Notification prefs | `UserDefaults` | `isDailyReminderEnabled` flag via `UserDefaultsNotificationStorage`. |

Both `ProgressStore` implementations use a shared `KeyValueStore` protocol that both `UserDefaults` and `NSUbiquitousKeyValueStore` conform to via extensions — allowing the `MockKeyValueStore` in tests to substitute either.

### Data Loading

The curriculum (~844KB) and mix pool (~8MB) are bundled JSON files, loaded via `FileCurriculumLoader` and `FileMixPoolLoader` respectively. Each uses a `FileReaderLoader` protocol (implemented by `LocalFileReader`) and a private `Mapper` class that keeps `Decodable` DTOs with `snake_case` keys encapsulated — domain models are never `Codable`.

Loaders expose a callback-based API (`CurriculumLoader` protocol) and are bridged to Combine publishers via `Deferred { Future { } }` extensions for use in `CurriculumViewModel`.

---

## 3. Testing

### Test Targets & Coverage

The project has 3 test targets with 26 test files covering domain logic, infrastructure, and ViewModels:

**`EssentialChessTests`** — Domain & Infrastructure (12 test files):

| Area | File | What it covers |
|---|---|---|
| Progress | `CurriculumProgressTrackerTests` | Section unlock logic, sub-theme/category/section progress calculation, 99% cap rule, exam unlock gate, 3-hour cooldown enforcement |
| Progress | `UserProgressUpdaterTests` | Immutable progress mutations (complete onboarding, mark puzzle, pass/fail exam, reset) |
| Progress | `UserProgressDailyStreakTests` | Streak increment on consecutive day, no-change on same day, reset on missed day, first-time initialization |
| Rating | `RatingCalculatorTests` | Placement K=100 and regular K=32 calculations, minimum rating floor (100), bracket assignment |
| Curriculum | `FileCurriculumLoaderTests` | JSON loading, mapper validation, error handling for invalid data |
| Mix Pool | `FileMixPoolLoaderTests` | JSON loading, difficulty tier mapping, error handling |
| Cache | `UserDefaultsProgressStoreTests` | Round-trip encode/decode of `UserProgress` through `ProgressCacheDTO` |
| Cache | `UbiquitousProgressStoreTests` | iCloud store read/write, UserDefaults→iCloud migration, backward-compatible optional field decoding |
| Cache | `UserDefaultsThemeStoreTests` | Theme settings persistence |
| Cache | `LocalFileReaderTests` | File reading from disk |
| Adapters | `ProgressAdapterTests`, `ThemeAdapterTests`, `LanguageAdapterTests` | Adapter state management, publisher emissions |
| Adapters | `CurriculumLoaderCombineTests`, `MixPoolLoaderCombineTests` | Combine publisher bridge from callback-based loaders |

**`EssentialChessUITests`** — ViewModel Logic (10 test files):

| ViewModel | Key scenarios tested |
|---|---|
| `ExamViewModelTests` | Initial state, correct/incorrect handling, hint costs life, 3-life depletion triggers `onFailed`, all-solved triggers `onPassed` |
| `PuzzleMixViewModelTests` | `actualRating` initialization from `hiddenRating`, ±150 range filtering, rating increase/decrease on solve, hint-as-failure, daily limit at 7, day-change reset, pool cycling on exhaustion, paywall trigger |
| `PuzzleStreakViewModelTests` | Streak increment, failure ends session, daily limit at 1, new-record detection |
| `OnboardingViewModelTests` | 15-puzzle assessment flow, rating calibration, completion callback |
| `CurriculumViewModelTests` | Section/category mapping, premium lock logic, exam state mapping |
| `PuzzleBoardViewModelTests` | Linear puzzle progression, frontier-based navigation, theme completion detection |
| `SettingsViewModelTests` | Haptic/sound toggle persistence, notification scheduling, permission handling |
| `StreakViewModelTests` | Publisher-driven streak count updates, "active today" detection |
| `MainNavigationViewModelTests` | Tab persistence, auto-save on change |
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
    Then section progress equals 0.99

  Scenario: Progress reaches 100% after exam is passed
    Given a section with a passed exam ID in the user's progress
    Then section progress equals 1.0

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

#### Puzzle Mix — Rating & Limits

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

  Scenario: Daily limit blocks free users after 7 puzzles
    Given a non-Pro user with 7 puzzles solved today
    When the next puzzle is requested
    Then showPaywall is true
    And no puzzle is loaded
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

| Item | Status |
|---|---|
| **In-app purchases** | UI and gating logic implemented. RevenueCat SDK integration is planned but not yet connected — `purchasePro()` currently sets `isPro = true` directly. `EnvironmentConfig` has placeholder API keys for staging/production. |
| **Puzzle Storm** | Placeholder "Coming Soon" view. `highestPuzzleStorm` field exists on `UserProgress` but no gameplay logic is implemented yet. |
| **Piece movement validation** | Delegated entirely to the `NativeChessBoard` package. The app layer handles puzzle completion/failure callbacks but does not implement its own move legality engine. |
| **Localization** | English and Bahasa Indonesia. String catalog (`Localizable.xcstrings`) is present. |
| **Accessibility** | Not explicitly implemented beyond standard SwiftUI defaults. |
| **Error handling** | Loader failures fall back to empty arrays (the app still launches). ProgressStore decode failures propagate as errors but are not surfaced to the user. |

---

## Screenshots & Demo

> \[TODO: Add App Store screenshots and demo video after release\]

---

## License

See [LICENSE](LICENSE) for details.
