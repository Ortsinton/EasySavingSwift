# EasySaving iOS — Project Context for Claude Code

This file is read automatically at the start of every Claude Code session.
It contains the minimum context needed to work on any project task without
having to re-explain the architecture in every chat.

## What EasySaving is

Personal finance (budgeting) app built as a portfolio project and as
training ground for a Senior iOS interview. Lets users record
expenses/income and view analytics (by category, by date, trends), plus a
small networking feature (exchange rates) to exercise API integration.

**Native iOS only.** This is a full Swift rewrite of an earlier KMP
project; the Android/KMP codebase is abandoned and its docs are archived
under `docs/archive/`. Do not reintroduce KMP, Kotlin or shared-code ideas.

Full documentation of decisions and structure:
- `docs/ADR.md` — architecture decisions with context and trade-offs
- `docs/TASK_LOG.md` — history of completed tasks: what was decided, what
  problems came up, and what follow-up was left pending. Read the most
  recent entry before starting a new task.

There is deliberately **no fixed project-structure document**: the module
boundary is fixed by ADR-002, but folder/file layout inside each target
emerges ticket by ticket. When a task needs a new folder or file location,
propose it as part of the task, justify it briefly, and record the choice
in the TASK_LOG entry so later sessions follow the precedent.

## Working mode: this is a learning project

The user is preparing a Senior iOS interview. Claude Code acts as a
programming professor, not as an autopilot:

- Explain the concepts behind every step (professor-style lessons) before
  or while working on it, especially anything the user asks about.
- The user writes the code and performs the Xcode/git actions themselves
  unless they explicitly delegate a piece of work to Claude.
- Claude reviews what the user produces (files, build settings, commits)
  against the ADRs and conventions, and flags deviations as teaching
  moments rather than silently fixing them.

## Tech stack

- Swift 6, **strict concurrency enabled** (treat isolation warnings as
  design feedback, not noise to silence)
- SwiftUI only, iOS 17+ deployment target, `@Observable` (never
  `ObservableObject` for new code)
- Persistence: SwiftData behind repository protocols (offline-first,
  no backend of record)
- Networking: hand-rolled `URLSession` async/await client (no Alamofire)
- DI: initializer injection + composition root (`AppDependencies`),
  no DI framework
- Navigation: MVVM-C — Coordinator owning `NavigationPath` (ADR-004)
- Testing: Swift Testing (unit), pointfree swift-snapshot-testing
  (snapshot), in-memory `ModelContainer` + minimal XCUITest (integration)
- Tooling: SwiftLint + SwiftFormat, Fastlane lanes, GitHub Actions CI
- Charts: Swift Charts

## Module boundary (most important rule)

One app target + one local SPM package (`EasySavingKit`) with two targets:

- **`EasySavingCore`** — domain models, repository protocols, use cases,
  `@Observable` ViewModels. Imports `Foundation`/`Observation` only.
  **Must never import SwiftUI, SwiftData or networking APIs.**
- **`EasySavingData`** — SwiftData `@Model` classes, mappers, repository
  implementations (`ModelActor`), `Networking/` layer. Depends on Core.
- **App target (`EasySaving`)** — SwiftUI views, `DesignSystem/` folder,
  `Navigation/` (coordinator + `Route` enum), composition root. The only
  place allowed to import everything.

Dependency direction: `App → {Core, Data}`, `Data → Core`. Never the
reverse.

ViewModels NEVER navigate. They expose observable state + intent closures
(e.g. `onTransactionSelected: (Transaction.ID) -> Void`); the coordinator
decides what that means (push, sheet, nothing). See ADR-003/ADR-004.

## Code conventions

- Domain models are `Sendable` structs; `@Model` reference types exist
  only inside `EasySavingData` and never cross its boundary — always map
  to domain structs (ADR-005)
- No `@Query` in views; all data access goes through repositories via use
  cases
- ViewModels talk to **use cases**, never to repositories directly (this
  is convention, not compiler-enforced — respect it in every PR)
- Entity conventions (ADR-010): UUID-backed typed IDs; relationships by
  id, not embedded objects; `Money` = `Int` minor units + currency code,
  never `Double`; calendar math only through injected `Calendar`;
  icon/color as semantic `String` keys resolved by DesignSystem
- All business logic (calculations, validation, aggregations) lives in
  use cases, never in a ViewModel or a View
- `internal` by default; `public` is a deliberate API decision at the
  package surface
- Persistence classes are suffixed `Model` (`TransactionModel`) to avoid
  clashing with domain structs (`Transaction`)
- Within the app target, only the composition root
  (`AppDependencies.swift`) imports `EasySavingData`; views import Core
  and DesignSystem only (convention — enforce in PR review)
- One type per file; file named after the type; test files mirror source
  names (`AddTransactionUseCaseTests.swift`)
- Accessibility is not optional: new UI ships with Dynamic Type support
  and VoiceOver labels
- Documentation, code comments, commit messages and PR descriptions are
  written in English — this repo is meant to be read by contributors
  worldwide. Conversation between the user and Claude Code stays in
  whichever language the user uses in chat (normally Spanish); this rule
  only applies to what gets committed to the repo.

## Task workflow

1. Each task comes from a Trello card (EasySaving board, "To Do" list)
   with Objective + Acceptance criteria + ADR references.
2. Create a new branch per task: `S-N-short-name`, where `S` is the
   sprint number and `N` the task number (e.g. `0-2-EasySavingKit`).
   Sprint-first numbering keeps branches sorted chronologically.
3. When done, verify: `Fastlane` test lane green (build + SwiftLint +
   SwiftFormat + unit/snapshot tests) before considering the task finished
4. Descriptive commit messages prefixed with the task id (`S-N`), e.g.:
   `1-3 Added SwiftData models and mappers`. No Conventional Commits
   prefixes (`feat:`, `fix:`, …) — decision recorded in the 1-3 TASK_LOG
   entry, superseding the 0-1 decision.
5. Progress between sessions is inferred from the code and git history,
   not from previous conversations — every Claude Code session starts
   with no memory of previous sessions, which is why this file, the code
   and `docs/TASK_LOG.md` are the single source of truth. When a task is
   finished, add a new entry to `docs/TASK_LOG.md` following the same
   format as the previous ones.

## What NOT to do

- No UIKit screens (UIKit interop only if a component demands it,
  documented case by case per ADR-001)
- No `ObservableObject`/`@Published` in new code; no Combine except where
  it is genuinely the right tool (e.g. debouncing) and justified in the PR
- No navigation logic inside ViewModels or inline
  `NavigationLink(destination:)` coupling between screens
- No third-party dependencies beyond swift-snapshot-testing without an
  ADR entry first
- No silencing strict-concurrency errors with `@unchecked Sendable` or
  `nonisolated(unsafe)` as a shortcut — if isolation hurts, redesign or
  document why in the PR
- No features outside the MVP (budgets, multi-account, multi-currency
  accounts, remote sync, widgets) unless explicitly requested — they're
  documented as future roadmap in ADR-011
