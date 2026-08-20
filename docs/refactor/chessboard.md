# ChessBoard Refactor Plan

This document is the working plan for refactoring the `ChessBoard/` module to align
with the project conventions defined in `.agents/skills/*/SKILL.md` (domain,
infrastructure, composition, navigation, mvvm-swiftui, tdd).

Status: **Draft** — updated as work progresses.

## 0. Decisions

### Scope decision: ChessBoard stays a standalone framework (Option A)

ChessBoard is **deliberately self-contained**: it bundles its own engine adapter
(ChessKit) and needs no dependency injection from outside. It is consumed by
`EssentialChessApp` and must remain an independent framework — it is never moved into
`EssentialChess/` nor does it receive injected dependencies from the app.

Refactor scope is therefore **internal only**: reorganize folders inside the single
`ChessBoard` framework target into clean layers (`Domain/`, `Geometry/`,
`Infrastructure/`, `iOS/`), mirroring the folder convention used by the
`EssentialChess` target — but without changing its independence or adding multi-target
modules.

Rationale: the app only ever talks to ChessBoard as a black box (`import ChessBoard`).
Splitting into `ChessBoardCore` + `ChessBoardUI` targets (Option B) only pays off if the
engine core needs reuse without UI (e.g. macOS app, watchOS, server-side engine). If
that need appears, migration is cheap: move `Domain/` + `Infrastructure/` into a new
`ChessBoardCore` target and add `ChessBoardUI` depending on it — the internal layering
established here becomes the split points.

---

## 1. Current State

### Folder layout

```
ChessBoard/
├── ChessBoard/
│   ├── ChessEngine/
│   │   ├── ChessEngine.swift        # adapter over ChessKit (+ domain primitives inside)
│   │   └── PGNAnnotation.swift      # public annotation values
│   ├── Shared/
│   │   ├── BoardGeometry.swift      # pure spatial math (CoreGraphics)
│   │   └── PuzzleValidator.swift    # pure move-sequence validator
│   └── iOS/
│       ├── Components/
│       │   ├── BoardInteractionHandler.swift
│       │   ├── HapticManager.swift      # singleton
│       │   ├── SoundManager.swift       # singleton
│       │   └── PromotionOverlayView.swift
│       ├── Puzzle/
│       │   ├── PuzzleChessBoardView.swift          (+ Setup / Interaction / Logic / Rendering)
│       └── Analysis/
│           └── AnalysisChessBoardView.swift        (+ Setup / Interaction / Logic / Rendering)
└── ChessBoardTests/
    ├── ChessEngineTests.swift
    ├── BoardGeometryTests.swift
    └── PuzzleValidatorTests.swift
```

The Xcode project uses `PBXFileSystemSynchronizedRootGroup`, so relocating files on
disk requires no manual `pbxproj` edits.

### Public API consumed by the app (must not break)

- `PuzzleChessBoardView` + `startPuzzle(fen:moves:)`, `startLearnThePiecesPuzzle(fen:)`,
  `setPieceTheme(_:)`, `setBoardTheme(light:dark:)`, `setHapticEnabled(_:)`,
  `setSoundEnabled(_:)`, `setHighlightColor(_:alpha:)`, `showHint()`, `showSolution()`,
  callbacks `onPuzzleCompleted` / `onPuzzleWrong` / `onPuzzleReady`.
- `PGNAnnotation`, `EngineColor`, `EnginePiece`, `EnginePieceKind`, `ChessEngine.GameState`.

## 2. Findings

| # | Problem | Skill |
|---|---------|-------|
| 1 | Domain primitives (`EngineColor`, `EnginePieceKind`, `EnginePiece`, `GameState`) and `PuzzleValidator` live inside infra/shared folders instead of a dedicated domain layer | `domain` |
| 2 | `ChessEngine` (ChessKit adapter) has no domain protocol — UI depends on the concrete class, hard to spy in tests | `domain`, `tdd` |
| 3 | `HapticManager.shared` / `SoundManager.shared` singletons are called directly by views (shared mutable singleton anti-pattern, not injectable) | `domain` (anti-pattern), `infrastructure` |
| 4 | ~90% duplication between `PuzzleChessBoardView` and `AnalysisChessBoardView` (grid setup, rendering, ghost/snapback, promotion, hint dots, arrows, castling help) | `composition` |
| 5 | `AnalysisChessBoardView.swift` carries an unused `internal import ChessKit` — dependency leak | `infrastructure` |
| 6 | `forceTurn` / `kingInCheckColor` manipulate FEN strings manually — fragile, not tested directly | `infrastructure` |
| 7 | Tests are incomplete: no protocol-based spies, engine sad paths (invalid FEN, castling, en passant, promotion set, `jump`, `boardPGNElements`) not covered | `tdd` |

### What is already clean (keep)

- Only `ChessEngine.swift` imports ChessKit — a good one-way dependency that should be preserved.
- `PuzzleValidator` and `BoardGeometry` are pure logic with no UIKit/ChessKit imports.
- Board views consume only domain primitives and the `ChessEngine` adapter — never ChessKit types directly.

## 3. Target Layout

```
ChessBoard/
├── ChessBoard/
│   ├── Domain/
│   │   ├── Models/
│   │   │   ├── EngineColor.swift
│   │   │   ├── EnginePieceKind.swift
│   │   │   ├── EnginePiece.swift
│   │   │   └── EngineGameState.swift
│   │   ├── Protocols/
│   │   │   └── ChessGameEngine.swift          # use-case protocol
│   │   └── UseCases/
│   │       └── PuzzleValidator.swift
│   ├── Geometry/
│   │   └── BoardGeometry.swift                # pure spatial math
│   ├── Infrastructure/
│   │   └── ChessKit/
│   │       └── ChessEngine.swift              # ONLY file importing ChessKit
│   └── iOS/
│       ├── Common/
│       │   ├── ChessBoardView.swift           # base view (shared rendering/interaction)
│       │   ├── BoardInteractionHandler.swift
│       │   ├── BoardArrowRenderer.swift
│       │   ├── PromotionOverlayView.swift
│       │   ├── HapticFeedback.swift           # BoardFeedback impl
│       │   ├── SoundFeedback.swift            # BoardFeedback impl
│       │   └── BoardFeedback.swift            # protocol
│       ├── Puzzle/
│       │   └── PuzzleChessBoardView.swift     (+ extensions, thin subclass)
│       └── Analysis/
│           └── AnalysisChessBoardView.swift   (+ extensions, thin subclass)
└── ChessBoardTests/
    ├── Domain/
    │   ├── PuzzleValidatorTests.swift
    │   └── ...
    ├── Infrastructure/
    │   └── ChessEngineTests.swift
    ├── Presenters/
    │   ├── PuzzleChessBoardViewTests.swift
    │   └── AnalysisChessBoardViewTests.swift
    └── Helpers/
        ├── XCTestCase+MemoryLeakTracking.swift
        └── TestFactories.swift
```

## 4. Phases

### Phase 1 — Layer separation (domain + infrastructure)

1. Move `EngineColor`, `EnginePieceKind`, `EnginePiece`, `GameState` to
   `Domain/Models/` as pure `Equatable` value types. No UIKit/ChessKit imports.
2. Move `PuzzleValidator` to `Domain/UseCases/` (it is already framework-free).
   Note: ChessBoard is a synchronous, single-implementation component — the domain rule
   "use cases are protocols" applies at the cross-module boundary (`ChessGameEngine`).
   Internal concrete logic helpers such as `PuzzleValidator` stay concrete classes.
3. Add `Domain/Protocols/ChessGameEngine.swift` — a capability protocol mirroring the
   chess use cases:
   - `piece(at:)`, `legalMoves(for:)`, `legalMoveCount()`
   - `move(from:to:promotion:)`, `wouldMoveResultInCheckmate(...)`
   - `sideToMove`, `currentFEN`, `kingInCheckColor`, `gameState`
   - `undo()`, `resetToStart()`, `jump(to:)`, `currentMoveId`, `boardPGNElements`
   - `forceTurn(to:)`, `isEnPassantCapture(from:to:)`
4. Move `ChessEngine` to `Infrastructure/ChessKit/` and conform it to `ChessGameEngine`.
   Rename `GameState` references to the new `EngineGameState` type.
5. Keep `BoardGeometry` under `Geometry/` (CoreGraphics primitives are acceptable for it).

Exit criteria: same behavior, all existing `ChessBoardTests` pass, and only
`ChessEngine.swift` imports ChessKit.

### Phase 2 — Decouple UI from infrastructure (composition + infrastructure)

6. Introduce `BoardFeedback` protocol (haptics + sound) and `BoardFeedbackService`
   implementations (`HapticFeedback`, `SoundFeedback`). Remove the singletons; inject
   `BoardFeedback` into views via init (with a no-op default for tests).
7. Extract a shared base class `ChessBoardView` holding all common UI concerns
   (containers, grid, piece rendering, ghost/snapback, highlights, hint dots,
   promotion overlay, arrow drawing, castling helpers). `PuzzleChessBoardView` and
   `AnalysisChessBoardView` become thin subclasses implementing only their mode logic.
8. Views accept the engine through `ChessGameEngine` and a factory closure, so tests can
   inject a spy.
9. Remove the unused `internal import ChessKit` from Analysis view files.

Exit criteria: no duplicated UI code between Puzzle and Analysis; no `*Manager.shared`
references from views; views compile against domain protocols only.

### Phase 3 — Test coverage (tdd)

10. Add `ChessGameEngineSpy` and `BoardFeedbackSpy` helpers; unit-test the views'
    interaction logic through the spies.
11. Complete `ChessEngineTests` sad paths: invalid FEN fallback, castling moves,
    en passant capture, all four promotions, `jump`, `boardPGNElements`.
12. Normalize test structure: `makeSUT` factories with memory-leak tracking across all
    feature test files, shared `TestFactories` + `any*`/`unique*` helpers.

Exit criteria: every phase introduces or covers tested behavior; no untested move paths
remain in the engine.

## 5. Constraints / Notes

- ChessBoard remains a standalone, self-contained framework — no external dependency
  injection (Option A, see section 0).
- Conventional Commits: scope `(board)` for all ChessBoard commits.
- Keep the public API listed in section 1 source-compatible for the app target.
- Do not change gameplay behavior in Phases 1–2; refactor only.
- If a future target (macOS app, watchOS, server engine) needs the core without UI,
  migrate to Option B: extract `Domain/` + `Infrastructure/` into a `ChessBoardCore`
  target. The layering from Phase 1 becomes the module split.
- `.agents/` is gitignored; project conventions live in `.agents/skills/`.