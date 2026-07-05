# EasySaving iOS — Task Log

This document complements the git history: while `git log` tells you *what*
changed, this log captures the *why* behind decisions made in each task, the
problems encountered during implementation, and any follow-up/debt left
pending. Every new Claude Code session should read the most recent entry
before starting the next task on the Trello board.

One entry is added per completed task, in chronological order. The log of the
abandoned KMP project is archived as `docs/archive/TASK_LOG-kmp.md`.

---

## Task 1: Create Xcode project with Swift 6 strict concurrency

**Branch/PR:** directly on `main` (bootstrap exception: the ticket itself
requires the initial commit on `main`, and branch protection does not exist
until Task 5). Every task from here on uses `task-N-short-name` branches.
**Commits:** `4652e45` (Xcode template), `7464512` (sanitized bootstrap:
build settings, placeholder, docs, `.gitignore`)
**References:** ADR-001, ADR-011

### Summary

Bootstrapped the `EasySaving` SwiftUI app from the Xcode 26.6 template and
brought it in line with ADR-001 before any real code exists: Swift 6
language mode, iOS 17.0 deployment target, template SwiftData boilerplate
removed in favor of a trivial placeholder view, Xcode-appropriate
`.gitignore`, and project docs (`CLAUDE.md`, `docs/ADR.md`,
`docs/SPRINT_PLAN.md`) committed. The old KMP project docs were archived
under `docs/archive/` with a `-kmp` suffix.

### Decisions made

- **Build settings live at project level; targets inherit.** `SWIFT_VERSION
  = 6.0` and `IPHONEOS_DEPLOYMENT_TARGET = 17.0` are defined once on the
  project; the per-target overrides the template generated were deleted.
  One source of truth — changing the floor for the whole repo is one edit.
- **No explicit `SWIFT_STRICT_CONCURRENCY` flag.** In Swift 6 language mode
  complete concurrency checking is mandatory; the flag only exists to opt
  in early from mode 5. Setting the language mode *is* the decision.
- **Deployment target is exactly 17.0, not Xcode's suggested 17.6.** 17.0
  is the ADR-001 rationale (`@Observable`, SwiftData); 17.6 would exclude
  devices on 17.0–17.5 for no defensible reason.
- **Template SwiftData code deleted** (`Item.swift`, the inline
  `ModelContainer` in `EasySavingApp`, `@Query` usage in `ContentView`).
  It violated three standing rules before any real code existed: `@Model`
  only in `EasySavingData` (ADR-005), no `@Query` in views (CLAUDE.md), and
  container wiring belongs to the composition root (ADR-007). SwiftData
  re-enters in Sprint 1 in its proper place. `ContentView` is now a plain
  `Text("EasySaving")`.
- **`CLAUDE.md` and `docs/` are visible in the Xcode navigator but have no
  target membership.** The template drag-in had put `CLAUDE.md` in the Copy
  Bundle Resources phase and `docs/` in the app target's
  `fileSystemSynchronizedGroups`, i.e. internal docs would ship inside the
  `.app`. Membership was removed at the *folder* level, not per file —
  per-file unchecking only creates a `membershipExceptions` blacklist, and
  any future file added to `docs/` would silently become a bundle resource
  again.
- **Archived KMP docs carry a `-kmp` suffix** (`ADR-kmp.md`,
  `PROJECT_STRUCTURE-kmp.md`, `TASK_LOG-kmp.md`) so they match the
  reference in `docs/ADR.md` and never share a filename with the living
  docs.
- **`.gitignore`:** `Package.resolved` is deliberately tracked — it is the
  shared dependency lockfile and the CI cache key (ADR-009). `xcuserdata/`,
  DerivedData, SPM build dirs and Fastlane artifacts are ignored.
- **Commit messages follow Conventional Commits** (`feat:`, `fix:`,
  `chore:`, `docs:` …), matching the example in CLAUDE.md.

### Problems encountered during implementation

- **Build settings were first changed only on the app target**, leaving the
  two test targets on Swift 5 / iOS 26.5. Root cause: Xcode preselects the
  target, not the project, in the settings editor. Fixed by moving the
  values to the project level (PROJECT column in the Levels view) and
  deleting the target overrides.
- **The deployment-target UI is misleading.** The setting's display name
  reads "iOS 17" while the actual value was `17.6`; the discrepancy was
  only caught by grepping `project.pbxproj`. Lesson recorded as practice:
  the pbxproj is the source of truth for settings review, not the Xcode UI.
- **Unused `import SwiftData` survived the boilerplate cleanup.** Swift
  emits no diagnostic for unused imports, and SwiftLint's `unused_import`
  rule only runs under `swiftlint analyze` (not part of the normal lint
  pass). Caught by grep — the same grep-the-boundary technique Task 2
  formalizes for the Core target.

### Verification

- App builds and runs on the iOS simulator showing the placeholder view.
- `grep -rn SwiftData EasySaving/` → no matches in the app target.
- `main` pushed to `EasySavingSwift` remote (note: the remote is named
  `EasySavingSwift`, not `origin`).

### Follow-up generated (not resolved in this task)

- **Decide the default-isolation posture.** The Xcode 26 template ships
  `SWIFT_APPROACHABLE_CONCURRENCY = YES` (all targets) and
  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (app target only). Both are
  currently *kept but undecided*. Whether the app target should default to
  `@MainActor` (Swift 6.2 "approachable concurrency") — and what the
  `EasySavingKit` package targets should do in Task 2, where ViewModels are
  `@MainActor` but repositories/use cases must not be — deserves a
  deliberate decision, probably an ADR note, before Sprint 1 code exists.
- **Task 2 must replace the placeholder's content**: the ticket requires
  the placeholder view to consume one public type from each Kit target to
  prove end-to-end linking.

---

## Task 2: Create EasySavingKit package and verify the module boundary

**Branch/PR:** `0-2-EasySavingKit` — first branch under the new
`S-N-short-name` convention (see Decisions).
**References:** ADR-002, ADR-007, ADR-008

### Summary

Created the local SPM package `EasySavingKit` at the repo root with the
two library targets mandated by ADR-002 (`EasySavingCore` with no
dependencies, `EasySavingData` depending on Core) plus Swift Testing test
targets for each. Wired both products into the app target. Each source
target ships one temporary public placeholder type
(`CorePlaceholder`, `DataPlaceholder` — the latter consumes the former,
proving the Data → Core arrow); the app's placeholder view displays both,
proving end-to-end linking. Ran the ticket's deliberate boundary
experiments — with a finding that corrects the ticket's own premise.

### Decisions made

- **Package location: repo root (`EasySavingKit/`), no intermediate
  `Packages/` folder.** With a single package the extra nesting is
  ceremony. Revisit if a second package ever appears (ADR-002 names
  target-per-feature as the natural next slice).
- **`swift-tools-version: 6.2`** — targets compile in Swift 6 language
  mode by default, matching the app project. `platforms: [.iOS(.v17)]`
  matches the app's deployment target.
- **Default actor isolation (resolves Task 1 follow-up):** package targets
  keep the compiler default (nonisolated); ViewModels will be annotated
  `@MainActor` explicitly when they land. Rationale: Core mixes
  presentation logic (main-actor) with use cases and repository protocols
  that must stay actor-agnostic so `ModelActor` repositories can do
  off-main work (ADR-003). The app target keeps the template's
  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — the UI layer is exactly
  the intended use case for module-wide MainActor default.
- **Views consume Core directly; Data reaches views only as plain data.**
  `ContentView` imports `EasySavingCore` and instantiates
  `CorePlaceholder`; `EasySavingApp` acts as the *embryonic composition
  root* (until `AppDependencies.swift` exists, Sprint 2), imports
  `EasySavingData` and injects `DataPlaceholder().text` as a `String`.
  Precedent recorded: views are infrastructure-agnostic, but Core is the
  view's vocabulary — "agnostic to Data" must not be over-rotated into
  "agnostic to the domain".
- **Branch naming convention changed** from `task-N-short-name` to
  `S-N-short-name` (sprint-first, e.g. `0-2-EasySavingKit`) so branches
  sort chronologically. CLAUDE.md and SPRINT_PLAN.md updated.
- **Swift Testing style:** no `test` prefix on test functions (discovery
  is driven by `@Test`, the XCTest naming convention is dead weight).

### Problems / findings during implementation

- **The ticket's boundary claim is false as written.** Acceptance
  criterion said a deliberate `import SwiftUI` inside Core "fails the
  build". Verified empirically: **it compiles.** Platform SDK frameworks
  (SwiftUI, SwiftData, UIKit, …) are ambient — visible to every module
  compiled against the SDK; SPM's `dependencies:` only gates *package*
  modules. The compiler-enforced boundary is real but narrower than the
  ticket implied:
  - `import EasySavingData` inside Core → `no such module` (undeclared
    package modules are invisible), and declaring it in `Package.swift`
    would be rejected as a dependency cycle. Two independent lines of
    defense.
  - `import SwiftUI` inside Core → compiles silently. Enforcement must be
    tooling: verified clean via grep for this task
    (`grep -rn 'import \(SwiftUI\|SwiftData\|UIKit\)' Sources/EasySavingCore/`);
    a SwiftLint `custom_rules` entry scoped to
    `EasySavingKit/Sources/EasySavingCore` is the permanent fix, deferred
    to Task 3. (Noted for interviews: building Core on Linux in CI, where
    UI/persistence frameworks don't exist, turns this into a true compile
    error; deliberately not adopted here — disproportionate.)
- **First draft of the placeholder wiring violated the project's own
  import convention**: `ContentView` imported `EasySavingData` directly.
  Caught in review, not by the compiler — intra-app-target conventions
  are social, exactly as ADR-002 warns. The fix produced the composition
  root precedent above.
- **`public` type ≠ usable type:** the memberwise initializer of a public
  struct is `internal`; placeholders needed explicit `public init()` to
  be constructible from the app target.

### Verification

- `swift build` / `swift test` green from the package directory (2 tests,
  2 suites — package is buildable standalone, no Xcode required).
- App builds and runs on simulator showing both placeholder texts.
- Boundary grep over `Sources/EasySavingCore/`: clean.

### Follow-up generated (not resolved in this task)

- **Task 3:** add the SwiftLint custom rule forbidding
  SwiftUI/SwiftData/UIKit imports inside `EasySavingCore` (and consider
  one for `EasySavingData` vs SwiftUI).
- **Sprint 1:** delete `CorePlaceholder`, `DataPlaceholder` and the
  `linkProof` wiring when the first real domain types and repositories
  land; `EasySavingApp`'s composition-root role moves to
  `AppDependencies.swift` (ADR-007) when real dependencies exist
  (Sprint 2).
- The ticket text in SPRINT_PLAN.md was *not* amended (it is a historical
  record); this entry is the canonical account of what the boundary check
  actually proves.
