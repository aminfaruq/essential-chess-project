# EssentialChess Layers Refactor Plan

This document is the working plan for refactoring `EssentialChess/` (and the
`EssentialChessApp` composition root) to align with the project conventions defined in
`.agents/skills/*/SKILL.md` (domain, infrastructure, composition, navigation,
mvvm-swiftui, tdd).

Status: **Draft** — updated as work progresses.

## Status Checklist

Progress: **9 / 12 sub-phases** done. Test suites green (`EssentialChess` 143 tests,
`EssentialChessUI` 187 tests, `platform=macOS`); app build verified with
`CODE_SIGNING_ALLOWED=NO`.

- Phase 0 — Baseline verification
  - [ ] P0: full test suite green + `CODE_SIGNING_ALLOWED=NO` build, counts recorded
- Phase 1 — Purify Domain (`domain`)
  - [x] 1a: `BeginnerProgress` conforms to `Hashable`
  - [x] 1b: `UserDefaults` / `NSUbiquitousKeyValueStore` conformances moved out of `Domain/`
  - [x] 1c: Combine removed from `BeginnerProgressStore` + `BeginnerProgressAdapter` added
  - [x] 1d: `Codable` stripped from `ThemeSettings` / `ECOOpening` / `ProFeature` (+ DTO raw strings)
- Phase 2 — Infrastructure DTOs (`infrastructure`)
  - [x] 2a: `ECOOpeningDTO` + mapper; `FileECOLoader` maps DTO → domain
  - [x] 2b: `ThemeSettingsDTO` + mapper; `UserDefaultsThemeStore` round-trips DTO
  - [x] 2c: unused `init() {}` removed from mappers
- Phase 3 — Presentation hygiene (`mvvm-swiftui`)
  - [x] 3a: adapters `@MainActor`, `DispatchQueue` hops removed
  - [x] 3b: injectable `currentDate` in `CurriculumViewModel` + deterministic cooldown test
- Phase 4 — Composable DI (`composition`)
  - [ ] 4a: convenience init on `DependencyContainer` / `AppComposer` + wiring tests

Tick a checkbox only after its exit criteria pass (tests green + build succeeds).

## 0. Decisions

### Scope decision: purify the existing layers, do not re-split modules (Option A)

The target layout is already correct: `EssentialChess/` is split into `Domain/`,
`Infrastructure/`, with presentation in the separate `EssentialChessUI` module and the
composition root in `EssentialChessApp/AppCore` (SceneDelegate → AppComposer →
DependencyContainer + ViewFactory). The refactor is therefore **content first**: fix
rule violations inside the existing files (Combine/Codable/Foundation leaks, missing
`Hashable`, stateful adapters, untestable composition) without moving entire modules.

The one structural change is moving two Foundation extension conformances out of the
`Domain/` folder into `Infrastructure/`. Everything else stays put.

Rationale: a module split (Option B: split `DomainCore` out of `EssentialChess`) only
pays off if another target needs the domain without infra/UI (e.g. a server or CLI).
The internal layering established here becomes those split points later.

### Combine-in-Domain rule

`AnyPublisher` is a presentation/Combine concept. Domain protocols must not import
`Combine`. Observability (who needs to react to changes) is a presentation concern and
belongs in an adapter layered on top of the pure store use case. See finding 1 and
phase 1c.

---

## 1. Current State

### Folder layout

```
EssentialChess/
├── EssentialChess/
│   ├── Domain/
│   │   ├── Models/
│   │   │   ├── BeginnerProgress.swift        # Equatable only (missing Hashable)
│   │   │   ├── CloudEvaluation.swift         # Hashable + Equatable ✓
│   │   │   ├── Curriculum.swift
│   │   │   ├── ECOOpening.swift              # Codable ⚠
│   │   │   ├── MixPool.swift
│   │   │   ├── ThemeSettings.swift           # Codable ⚠
│   │   │   ├── UserProgress.swift            # ProFeature enum is Codable ⚠
│   │   ├── Protocols/
│   │   │   ├── BeginnerProgressStore.swift   # imports Combine ⚠
│   │   │   ├── BoardSettingsStore.swift
│   │   │   ├── CloudEvaluationLoader.swift
│   │   │   ├── CurriculumLoader.swift
│   │   │   ├── ECOLoader.swift
│   │   │   ├── FileReaderLoader.swift
│   │   │   ├── HTTPClient.swift
│   │   │   ├── KeyValueStore.swift           # has UserDefaults (+iCloud) extensions ⚠
│   │   │   ├── LanguageStore.swift
│   │   │   ├── MixPoolLoader.swift
│   │   │   ├── NotificationSchedulerLoader.swift
│   │   │   ├── NotificationStore.swift
│   │   │   ├── ProgressLoader.swift
│   │   │   ├── TabStore.swift
│   │   │   └── ThemeLoader.swift
│   │   └── UseCases/
│   │       ├── CurriculumProgressCalculator.swift
│   │       ├── ECODetector.swift              # class (minor)
│   │       ├── RatingCalculator.swift         # Foundation pow (minor)
│   │       ├── UserProgress+DailyStreak.swift
│   │       └── UserProgressUpdater.swift
│   ├── Infrastructure/
│   │   ├── Adapters/
│   │   │   ├── CurriculumLoader+Combine.swift # presentation-facing publisher ✓
│   │   │   ├── LanguageAdapter.swift          # ObservableObject + DispatchQueue.main ⚠
│   │   │   ├── MixPoolLoader+Combine.swift    # presentation-facing publisher ✓
│   │   │   ├── ProgressAdapter.swift          # ObservableObject + DispatchQueue.main ⚠
│   │   │   ├── ThemeAdapter.swift             # ObservableObject + DispatchQueue.main ⚠
│   │   │   └── UserNotificationsAdapter.swift # DispatchQueue.main, protocol-collaborator ✓
│   │   ├── Loaders/
│   │   │   ├── CloudEvaluation/
│   │   │   │   ├── CloudEvaluationMapper.swift  # static mapper, unused init {}
│   │   │   │   └── RemoteCloudEvaluationLoader.swift  ✓
│   │   │   ├── Curriculum/
│   │   │   │   ├── CurriculumMapper.swift       # Root DTO ✓
│   │   │   │   └── FileCurriculumLoader.swift   ✓
│   │   │   ├── ECO/
│   │   │   │   └── FileECOLoader.swift          # decodes domain ECOOpening directly ⚠
│   │   │   └── MixPool/
│   │   │       ├── FileMixPoolLoader.swift      ✓
│   │   │       └── MixPoolMapper.swift          # Root DTO ✓
│   │   ├── Networking/
│   │   │   ├── LocalFileReader.swift            ✓
│   │   │   └── URLSessionHTTPClient.swift       ✓
│   │   └── Persistence/
│   │       ├── Progress/
│   │       │   ├── ProgressCacheDTO.swift       ✓ proper DTO
│   │       │   ├── UbiquitousProgressStore.swift
│   │       │   ├── UserDefaultsBeginnerProgressStore.swift  # exposes progressPublisher
│   │       │   ├── UserDefaultsProgressLoader.swift
│   │       ├── UserDefaultsBoardSettingsStore.swift
│   │       ├── UserDefaultsLanguageStore.swift
│   │       ├── UserDefaultsNotificationStore.swift
│   │       ├── UserDefaultsTabStore.swift
│   │       └── UserDefaultsThemeStore.swift     # encodes/decodes domain ThemeSettings ⚠
├── EssentialChessUI/
│   └── ViewModels/                              # pure @Published, no UIKit/SwiftUI ✓
├── EssentialChessApp/AppCore/
│   ├── SceneDelegate.swift                      # composition root ✓
│   ├── AppComposer.swift                        # no injection, testable-missing ⚠
│   ├── DependencyContainer.swift                # hardcoded concrete instances ⚠
│   ├── ViewFactory.swift
│   ├── EnvironmentConfig.swift
│   └── AppRootView.swift / RootView.swift
├── EssentialChessTests/                         # makeSUT + trackForMemoryLeaks ✓
└── EssentialChessUITests/ViewModels/            # 186 tests, makeSUT ✓
```

### Note on the test suite

All test targets are healthy: naming `test_...`, `makeSUT`, memory-leak tracking, and
spies across 18+ files. TDD conventions are treated as **already compliant** and out of
scope for this refactor.

## 2. Findings

| # | Problem | Where | Skill |
|---|---------|-------|-------|
| 1 | `import Combine` + `progressPublisher: AnyPublisher<...>` in a domain protocol — observability is a presentation concern | `Domain/Protocols/BeginnerProgressStore.swift:8,11` | `domain` |
| 2 | Domain models conform to `Codable` (an infrastructure concern) — the skill lists `Decodable` conformance as an explicit anti-pattern | `Domain/Models/ThemeSettings.swift`, `Domain/Models/ECOOpening.swift`, `Domain/Models/UserProgress.swift` (`ProFeature: String, Codable`) | `domain` |
| 3 | Concrete Foundation classes conform in a `Domain/` file | `Domain/Protocols/KeyValueStore.swift:15,17` (`extension UserDefaults` / `extension NSUbiquitousKeyValueStore`) | `domain` |
| 4 | `BeginnerProgress` is `Equatable` but missing `Hashable` (rule: immutable value types are `Hashable`/`Equatable`) | `Domain/Models/BeginnerProgress.swift:8` | `domain` |
| 5 | `FileECOLoader` decodes straight into the domain model `[String: ECOOpening]`; `UserDefaultsThemeStore` round-trips domain `ThemeSettings` — no DTO, encouraged by finding 2 | `Infrastructure/Loaders/ECO/FileECOLoader.swift`, `Infrastructure/Persistence/UserDefaultsThemeStore.swift` | `infrastructure` |
| 6 | Mapper types are classes with an unused `public init() {}` (they're stateless static mappers) | `CloudEvaluationMapper`, `CurriculumMapper`, `MixPoolMapper` | `infrastructure` |
| 7 | Stateful `ObservableObject` adapters in Infrastructure emit on main via `DispatchQueue.main.async` (7 sites) instead of `@MainActor` | `ProgressAdapter`, `ThemeAdapter`, `LanguageAdapter`, `UserNotificationsAdapter` | `mvvm-swiftui` |
| 8 | `CurriculumViewModel.mapExamState` reads `Date()` directly (line 239) — bypasses domain `canStartExam(categoryID:progress:currentDate:)` and breaks deterministic cooldown tests | `EssentialChessUI/ViewModels/Curriculum/CurriculumViewModel.swift:239` | `mvvm-swiftui`, `tdd` |
| 9 | `AppComposer()` / `DependencyContainer()` build concrete instances inline with no convenience init — composition is not injectable, cannot be tested without the UI | `EssentialChessApp/AppCore/AppComposer.swift:27`, `DependencyContainer.swift:27` | `composition` |

### What is already clean (keep)

- Domain use cases are pure logic (`CurriculumProgressCalculator`, `RatingCalculator`,
  `UserProgressUpdater`, daily-streak) and error types stay abstract at the boundary.
- Infrastructure loaders are well-built: `URLSessionHTTPClient`, `RemoteCloudEvaluationLoader`
  (weak self + status/map errors), `FileCurriculumLoader`/`FileMixPoolLoader` with private
  DTO roots, `ProgressCacheDTO` is a proper DTO.
- ViewModels are pure — verified: **no** `UIKit`/`SwiftUI`/`URLSession`/`CoreData` imports,
  `@Published` state, injected protocol collaborators, dumb UI models.
- Composition root exists and is a single path (`SceneDelegate` → `AppComposer` →
  `AppRootView`).
- The send/receive error paths on remote loaders use `Result` and abstract errors.

## 3. Target Layout

Only additive/moved files shown; everything else keeps its path.

```
EssentialChess/
├── EssentialChess/
│   ├── Domain/
│   │   ├── Models/
│   │   │   ├── BeginnerProgress.swift          # + Hashable
│   │   │   ├── ECOOpening.swift                # Codable removed
│   │   │   ├── ThemeSettings.swift             # Codable removed
│   │   │   ├── UserProgress.swift              # ProFeature keeps Hashable, loses Codable
│   │   ├── Protocols/
│   │   │   ├── BeginnerProgressStore.swift     # Combine removed (pure load/save only)
│   │   │   └── KeyValueStore.swift             # protocol only, extensions moved out
│   └── Infrastructure/
│       ├── Adapters/
│       │   ├── BeginnerProgressAdapter.swift   # NEW — @MainActor @Published facade
│       │   └── (Progress/Theme/Language/Notification adapters)  # @MainActor
│       ├── Loaders/
│       │   ├── ECO/
│       │   │   ├── ECOOpeningDTO.swift         # NEW
│       │   │   ├── ECOOpeningMapper.swift      # NEW
│       │   │   └── FileECOLoader.swift         # decodes DTO, maps to domain
│       │   └── (mappers)                       # remove unused init {}
│       └── Persistence/
│           ├── KeyValueStore+UserDefaults.swift        # MOVED (new file)
│           ├── KeyValueStore+Ubiquitous.swift          # MOVED (new file)
│           ├── Theme/
│           │   ├── ThemeSettingsDTO.swift      # NEW
│           │   ├── ThemeSettingsMapper.swift   # NEW
│           │   └── UserDefaultsThemeStore.swift# MOVED (DTO round-trip)
│           └── Progress/
│               └── ProgressCacheDTO.swift      # stores raw String sets, not ProFeature
EssentialChessApp/AppCore/
├── DependencyContainer.swift                   # + convenience init(… stores/loaders)
└── AppComposer.swift                           # + convenience init(container:)
```

## 4. Phases

Phases ship as **tiny commits** — never batched. Each phase keeps the branch buildable
and green. Conventional Commits scope: `(layers)`.

### Phase 0 — Baseline (verification only)

1. Run the full test suite and a `CODE_SIGNING_ALLOWED=NO` app build.
2. Note the exact pass count and build status in the doc so later phases can diff against
   it.

Exit criteria: all tests pass, app builds. No code changes.

### Phase 1 — Purify the Domain layer (domain)

#### 1a — Hashable on BeginnerProgress — DONE
- Make `BeginnerProgress` conform to `Hashable` (`Domain/Models/BeginnerProgress.swift`).
- No test changes expected; verify compile + tests still green.

#### 1b — Move Foundation conformances out of Domain — DONE
- Strip `extension UserDefaults` / `extension NSUbiquitousKeyValueStore` from
  `Domain/Protocols/KeyValueStore.swift` (leave the protocol + `import Foundation` only).
- Add `Infrastructure/Persistence/KeyValueStore+UserDefaults.swift` and
  `Infrastructure/Persistence/KeyValueStore+Ubiquitous.swift` with the conformances.
- Keep the `KeyValueStore.swift` protocol file in the same folder so consumers don't
  move; only the conformances relocate.

#### 1c — Remove Combine from the domain protocol — DONE
- `Domain/Protocols/BeginnerProgressStore.swift`: drop `import Combine` and
  `progressPublisher`. Keep only pure load/save use cases (`load(completion:)`,
  `save(_:completion:)`) returning `Result`-typed completions.
- Add `Infrastructure/Adapters/BeginnerProgressAdapter.swift`:
  `@MainActor final class BeginnerProgressAdapter: ObservableObject` with
  `@Published var progress: BeginnerProgress` and a `publisher()` used by the
  struggling type. It wraps the concrete `UserDefaultsBeginnerProgressStore`.
- `UserDefaultsBeginnerProgressStore`: remove the `progressPublisher` computed property
  (its subject moves into the adapter).
- Wire in `DependencyContainer`: replace `beginnerProgressStore.progressPublisher` with
  `container.beginnerProgressAdapter.publisher()` in `AppComposer` and adapt
  `BeginnerCurriculumViewModel`'s input.
- Update `UserDefaultsBeginnerProgressStoreTests` / beginner VM tests to use the adapter.

#### 1d — Strip Codable from domain models — DONE
- `Domain/Models/ThemeSettings.swift`, `Domain/Models/ECOOpening.swift`: remove
  `Codable` conformances (and nested `Codable` on `RGBAColor` / `BoardThemeOption`).
- `Domain/Models/UserProgress.swift`: change `ProFeature` from `String, Codable` to
  `String, Hashable` only.
- `Infrastructure/Persistence/Progress/ProgressCacheDTO.swift`: encode `ProFeature`
  values as raw `String` sets instead of the enum, and map back in `toModel()`.
- Follow with Phase 2's DTO work so nothing compiles-grey in between.

Exit criteria: no `import Combine`, no mere model `Codable`, no Foundation conformance
extension under `Domain/`; all tests green (compensating changes handled as needed).

### Phase 2 — Infrastructure DTOs and mapper cleanup (infrastructure)

#### 2a — ECO DTO — DONE
- Add `ECOOpeningDTO` (structure mirrors the JSON payload) + `ECOOpeningMapper`
  (static `map(_:) -> [String: ECOOpening]`, mirroring the mapper style).
- `FileECOLoader` decodes `ECOOpeningDTO` and maps to the domain dictionary.
- Update `FileECOLoaderTests` to cover the DTO decode + map (fixtures unchanged).

#### 2b — Theme DTO — DONE
- Add `ThemeSettingsDTO` + `ThemeSettingsMapper` (static); move
  `UserDefaultsThemeStore` into `Infrastructure/Persistence/Theme/` and make it
  round-trip the DTO.
- Update `UserDefaultsThemeStoreTests` to verify DTO encode/decode and mapping.

#### 2c — Mapper init cleanup — DONE
- Remove the unused `public init() {}` from `CloudEvaluationMapper`,
  `CurriculumMapper`, `MixPoolMapper` (static usage only).
- Update tests that instantiate mappers, if any.

Exit criteria: all infra decode/encode goes through DTOs; no mapper has a public init.

Deviations from this plan (documented):
- **1c**: `BeginnerProgressAdapter` is a plain `ObservableObject` (mirroring the existing
  `ProgressAdapter` style), **not** `@MainActor` yet. The `@MainActor` annotation is
  deferred to 3a so all adapters are converted uniformly. Also the store keeps a plain
  in-memory `_progress` value instead of a `CurrentValueSubject`.
- **2a**: no separate `ECOOpeningDTO.swift`; the DTO is a private nested struct inside
  `ECOOpeningMapper.swift`, matching the existing `MixPoolMapper`/`CurriculumMapper`
  convention.
- **2b**: `ThemeSettingsDTO.swift` lives flat in `Infrastructure/Persistence/` and
  `UserDefaultsThemeStore.swift` stays where it is — no `Persistence/Theme/` subfolder
  move (cosmetic only; kept minimal). The DTO follows the `ProgressCacheDTO`
  `init(settings:)` / `toModel()` style.
- Phase 1 & 2 shipped as seven tiny commits; **DTO work (2a, 2b) landed before 1d** so every
  commit builds: stripping `Codable` (1d) only happens after nothing in Infrastructure
  decodes the domain models directly anymore (2a `ECOOpeningMapper`, 2b
  `ThemeSettingsDTO`). Commit order: 1a → 1b → 1c → 2a → 2b → 1d → 2c.

### Phase 3 — Presentation hygiene (mvvm-swiftui)

#### 3a — @MainActor adapters — done
- `LanguageAdapter`, `ThemeAdapter`, `ProgressAdapter`, `UserNotificationsAdapter`,
  `BeginnerProgressAdapter` annotated `@MainActor`; the seven `DispatchQueue.main.async`
  hops deleted.
- Cascade: composition root (`DependencyContainer`, `AppComposer`, `ViewFactory`,
  `SceneDelegate`) and `SettingsViewModel` annotated `@MainActor`. `NotificationSchedulerLoader`
  completion params annotated `@MainActor` so the scheduler (spy calls it synchronously)
  keeps single-runloop semantics without `Task { @MainActor }` hops in the VM.
- Shipped as four commits (protocol+adapters / adapter tests / AppCore / VM+tests).
- Committed with no `DispatchQueue` hops remaining in adapters.

#### 3b — Injectable clock in CurriculumViewModel — done
- Added `currentDate: () -> Date = { Date() }` to `CurriculumViewModel` init, used in the
  cooldown check (replacing line 239's direct `Date()`).
- Cooldown tests now deterministic: `test_load_examOnCooldown_showsCooldownState_deterministically`
  (failure 30 min ago → `.onCooldown`) and
  `test_load_examAfterCooldownExpired_showsUnlockedState_deterministically` (failure 4 h ago →
  `.unlocked`), both with a fixed injected clock via `makeSUT(now:)`.

Exit criteria: no `DispatchQueue.main.async` in adapters; cooldown logic is
deterministic under test.

### Phase 4 — Composable dependency injection (composition)

#### 4a — Injectable container/composer — pending
- `DependencyContainer`: add a convenience init accepting the stores/loaders
  (defaulting to the current production instances). Keep the production `init()` as the
  zero-arg default.
- `AppComposer`: add `init(container: DependencyContainer)` (production `init()` keeps
  the current behavior). Wire VMs from the injected container instead of building them.
- Add `DependencyContainerTests` / `AppComposerTests` (in the app target) that build the
  container with a test double (e.g. stub `KeyValueStore`) and assert wiring — no UI
  needed.

Exit criteria: composition root is injectable; new tests build the container without
running the app.

## 5. Constraints / Notes

- Behavior must not change in any phase; this is a refactor, not a feature change.
- Conventional Commits: scope `(layers)` for all commits in this plan.
- Fast test command (macOS target): `xcodebuild test -workspace EssentialChessApp/EssentialChessApp.xcworkspace -scheme EssentialChess -destination 'platform=macOS'`.
  The `EssentialChess` scheme supports macOS, so unit tests run much faster than on the iOS Simulator.
- Do not touch project files unless the renamed/moved files require it
  (`PBXFileSystemSynchronizedRootGroup` auto-syncs folder moves — verify after each move).
- `docs/refactor/essentialchess.md` is untracked like `chessboard.md`; commit it with
  `git add -f docs/refactor/essentialchess.md` alongside the phase that matters, or
  update in place and commit once alongside Phase 1.
- `.agents/` is gitignored; conventions live in `.agents/skills/`.
- Test suite is already convention-compliant (see section 1 note) — phases only fix the
  production code; tests are updated only where they assert behavior that changed.
- Future split (Option B): moving the purified `Domain/` into its own target is trivial
  because Phase 1 removes its framework dependencies. The layering this plan establishes
  becomes the module boundaries.