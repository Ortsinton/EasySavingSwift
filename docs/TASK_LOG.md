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

---

## Task 3: SwiftLint + SwiftFormat + Fastlane lanes

**Branch/PR:** `0-3-linting-and-fastlane`
**References:** ADR-002 (boundary enforcement), ADR-009 (amended in this
task)

### Summary

Made code quality a command: SwiftLint and SwiftFormat are consumed as SPM
command plugins declared in `EasySavingKit/Package.swift`, configured by
`.swiftlint.yml` / `.swiftformat` at the repo root, and orchestrated by
three Fastlane lanes (`lint`, `test`, `snap`) that are the exact commands
CI will run in Task 5. The SwiftLint `custom_rules` now enforce the
ADR-002 module boundary that the compiler cannot (closing the Task 2
follow-up), and they caught a real violation on their first run. A
minimal `README.md` was created (the repo had none) documenting setup and
lanes. All placeholder code was reformatted; both lanes run green
locally.

### Decisions made

- **Binary delivery: SPM plugins, not Homebrew/Mint/downloaded binaries.**
  Everything is self-contained and pinned by `Package.resolved`; no
  machine-level tooling to keep in sync. Recorded as an amendment to
  ADR-009, which satisfies the "no third-party dependency without an ADR
  entry" rule — the plugins are build-time tools, never linked into
  shipping code. Plugins are declared in `EasySavingKit/Package.swift`
  because it is the only package in the repo; revisit if a dedicated
  tooling package ever becomes justified.
- **Two lockfiles, both tracked.** The CLI writes
  `EasySavingKit/Package.resolved`; Xcode writes
  `EasySaving.xcodeproj/.../xcshareddata/swiftpm/Package.resolved` at
  workspace level. Same purpose, different resolver; `xcshareddata` is
  the shared (committed) half of Xcode state, unlike `xcuserdata`.
- **Ownership split between the tools:** SwiftFormat owns formatting;
  SwiftLint owns semantic/style rules and architecture rules. SwiftLint
  rules that overlap with SwiftFormat are explicitly disabled so the two
  tools can never disagree about the same line.
- **Single `.swiftlint.yml`; strictness is a lane concern.** The lane
  passes `--strict` (warnings become errors) instead of maintaining a
  duplicated CI config. Since the lane is the same command locally and in
  CI, strict mode applies everywhere by construction.
- **Boundary rules as `custom_rules`:** `core_boundary` bans
  SwiftUI/SwiftData/UIKit imports in `EasySavingCore`; `data_boundary`
  bans UI framework imports in `EasySavingData`. This moves the boundary
  from review-enforced to tooling-enforced (the compiler tier is
  unreachable for ambient SDK frameworks, per Task 2's finding).
- **`.swiftformat` stays near defaults on purpose** (swiftversion 6.2 +
  excludes): fewer deviations, less bikeshedding.
- **No lint/format in Xcode build phases.** Run Script phases pay lint on
  every incremental build, fight the Xcode 15+ script sandbox, and
  invoking SwiftPM inside xcodebuild is reentrant; a formatter rewriting
  sources during a build breaks build determinism outright. Enforcement
  lives at the integration point (CI + branch protection, Task 5);
  `SwiftLintBuildToolPlugin` (in-editor feedback) and a pre-commit hook
  running the lint lane are documented as deliberate deferrals.
- **CI never rewrites code.** The lint lane uses check modes only
  (`swiftformat --lint`, `swiftlint lint`); formatting is a local,
  explicit developer action. Format check runs before lint in the lane:
  cheapest check first, fail fast.

### Problems / findings during implementation

- **System Ruby (2.6, EOL) cannot install modern fastlane** and its gem
  dir is root-owned. Fixed by installing Homebrew + `brew install ruby`
  (user-writable prefix, no sudo). rbenv/mise with a `.ruby-version` is
  the team-scale answer; one machine didn't justify it.
- **`sourcekitdInProc` fatal error was the toolchain, not the sandbox.**
  SwiftLint crashed loading SourceKit because `xcode-select` pointed at
  `/Library/Developer/CommandLineTools`, which ships no
  `sourcekitdInProc.framework`. `--disable-sandbox` was tested and made
  no difference; the fix is `sudo xcode-select -s
  /Applications/Xcode.app/Contents/Developer`. SwiftLint needs SourceKit
  here precisely because of `custom_rules` (syntax map to avoid matching
  inside comments/strings).
- **Each plugin runs its binary from a different working directory**
  (empirical finding; documented nowhere): SwiftLint runs from the
  package directory, SwiftFormat from the invocation directory. Hence the
  two separate path lists in the Fastfile.
- **The SPM plugin write sandbox is deny-by-default outside the package.**
  `--allow-writing-to-package-directory` covers only the package dir;
  formatting app-target sources requires `--allow-writing-to-directory .`.
  The lint lane needs no write grant at all — a least-privilege split the
  sandbox enforced for us.
- **The SwiftLint command plugin lints every file twice** (forwarded
  paths are also appended by the plugin). Cosmetic duplication in output;
  accepted rather than fought.
- **`core_boundary` caught a real `import SwiftUI` in
  `CorePlaceholder.swift`** (uncommitted local edit) on its first
  execution — the rule paid for the task before the task was finished.
- **CLI test noise, all benign:** `IDELaunchParametersSnapshot / no
  debugger version` spam (xcodebuild queries LLDB, which doesn't exist in
  CLI runs) and one transient `xctrunner` launch failure on a simulator
  clone (parallel UI testing race; xcodebuild recovered, suite green).

### Verification

- `bundle exec fastlane lint` and `bundle exec fastlane test` green
  locally; SwiftFormat check reports 0 files requiring formatting.
- Test pyramid measured on this repo: package tests ~3 s vs app-target
  tests ~111 s (of which ~87 s are template UI tests) — two orders of
  magnitude, with numbers to cite when concentrating tests in the package
  during Sprints 1–2.

### Follow-up generated (not resolved in this task)

- **Task 4:** the `snap` lane is a placeholder; wire it to the snapshot
  suite when the infrastructure lands.
- **Task 5 (CI):** pre-grant plugin trust/permissions (no interactive
  prompt on runners); consider `parallel_testing: false` and
  `number_of_retries: 1` in `run_tests` for slower runners; SPM cache
  keyed on `Package.resolved`; add the CI badge to the README.
- **Deferred by decision:** `SwiftLintBuildToolPlugin` per target for
  in-editor violations; pre-commit hook running `fastlane lint`.
- Minor: simulator runtime fallback notice (`Runtime build '23F81a' not
  found`) — update runtimes via Xcode Settings → Components someday.

---

## Task 4: Snapshot testing infrastructure

**Branch/PR:** `0-4-snapshot-testing`
**References:** ADR-008; closes the Task 3 follow-up (`snap` lane
placeholder)

### Summary

Added `pointfreeco/swift-snapshot-testing` 1.19.2 as an Xcode-project
package dependency linked **only** to the app test target
(`EasySavingTests`), wrote the first snapshot test
(`Snapshots/ContentViewSnapshotTests.swift`, Swift Testing, `@MainActor`)
against the placeholder view with a fully pinned rendering contract
(fixed input, fixed layout, forced light appearance), wired the `snap`
lane to the suite, and documented the record/verify workflow and pinned
environment in `docs/TESTING.md`. The task's real deliverable turned out
to be an investigation: the same test rendered differently under Xcode
and `xcodebuild`, which produced the repo's snapshot layout policy.

### Decisions made

- **One product linked, not three.** Xcode's add-package sheet offers
  `SnapshotTesting`, `InlineSnapshotTesting` and
  `SnapshotTestingCustomDump`; only the first is linked. Unlinked
  products are never compiled — linking `InlineSnapshotTesting` would
  have paid swift-syntax's build cost on every clean build for an API
  nobody decided to use. Note: `Package.resolved` still pins the *whole*
  dependency graph (swift-syntax, swift-custom-dump,
  xctest-dynamic-overlay) regardless of which products are linked —
  resolution and build are different phases; the lockfile entries are
  expected and harmless.
- **Dependency lives at the Xcode project level, not in
  `EasySavingKit/Package.swift`** — the ticket scopes it to the app test
  target, and Core's tests couldn't render SwiftUI anyway (ADR-002).
  Only the `xcshareddata` lockfile changed, consistent with the
  two-lockfile split documented in Task 3.
- **Snapshot layout policy** (recorded in `docs/TESTING.md`): screens
  use `.fixed(width: 390, height: 844)`; DesignSystem components (Sprint
  2+) will use `.sizeThatFits`; **`.device(config:)` is banned** — see
  findings. Corollary discovered via a zero-size render error: a
  screen-shaped SwiftUI view must never "measure itself"
  (`.sizeThatFits` on a hosted screen returns zero); the canvas size is
  part of the test contract.
- **Exact precision, no tolerances.** `precision`/`perceptualPrecision`
  stay at their defaults; introducing a tolerance requires a documented
  justification in the PR. Rationale: our one observed nondeterminism
  was geometric (a variable to eliminate), not antialiasing noise (a
  difference to tolerate), and a pixel-fraction tolerance is exactly the
  size of a small real regression.
- **`swiftTestingTestCaseNames` stays enabled, knowingly** (see
  findings for the incident). Consequences accepted: `@Test` function
  names are backticked raw identifiers, and snapshot artifact names are
  their dash-sanitized form (`placeholder-view-light.1.png`).
- **`snap` lane filters by `only_testing:` at `Target/Suite`
  granularity** — the lane is the executable definition of "the snapshot
  suite" that CI will call in Task 5. Accepted cost: each new snapshot
  suite must be added to the list; migrating to a dedicated
  `.xctestplan` is the planned upgrade once the list outgrows 2–3
  entries. `only_testing` filters execution, not compilation — the lane
  builds the full scheme.
- **Structure precedents:** snapshot tests live under
  `EasySavingTests/Snapshots/` (suites will grow parallel to
  `DesignSystem/`); `__Snapshots__/` references are committed; repo docs
  are SCREAMING_CASE by precedent (`TESTING.md`, not the ticket's
  `testing.md`).

### Problems / findings during implementation

- **Snapshot reference identity is derived from source code.** The
  reference path is `<test file name>/<test function name>.<assert
  index>.png`; renaming either orphans the reference and silently
  records a new one. Learned twice in one task: first fixing a typo
  (`ContenView…`), then when **SwiftFormat's `swiftTestingTestCaseNames`
  rule renamed the test function itself** (camelCase → backticked raw
  identifier) and invalidated the reference recorded minutes earlier.
  A formatter that renames identifiers stretches the Task 3 "SwiftFormat
  owns formatting" contract — accepted because the rule only touches
  `@Test` functions and its behavior is version-pinned by
  `Package.resolved` (no silent drift, unlike a brew-installed binary).
- **The headline finding: `.device(config:)` layouts are
  runner-sensitive.** References recorded from Xcode failed under
  `bundle exec fastlane snap` and vice versa, each runner perfectly
  self-consistent. Isolated empirically: both runs used the same
  simulator and runtime (proven via `xcresulttool` device info: iPhone
  17, iOS 26.5 23F77); headless-vs-windowed was ruled out (fails with
  Simulator.app open); pixel forensics showed a **pure vertical
  translation of 10 px @3x (3.33 pt) with zero residual diff** after
  shift correction — i.e. the same render positioned differently,
  implying a ~6.7 pt disagreement in effective top safe-area inset.
  Mechanism (from the library source): `.device` simulates safe area by
  overriding `UIWindow.safeAreaInsets` on a scene-less window — a hack
  UIKit honors differently depending on the host process environment,
  and whose fragility the library's own code comments admit. Upstream
  issue family: swift-snapshot-testing #810, #180, #430, discussion
  #558; the exact divergence lives inside UIKit and is not publicly
  documented. Resolution: eliminate the variable (`.fixed` layout), not
  tolerate it (precision) — verified deterministic across both runners
  afterwards.
- **CLI environment note:** system Ruby shadowing struck again (a shell
  without the Homebrew PATH picked `/usr/bin/bundle`, Ruby 2.6, and
  failed on the bundler version) — same root cause as Task 3, worth
  remembering for CI runner setup in Task 5.

### Verification

- Record → verify cycle deterministic: first run records and fails by
  design, second run green, **in both runners against the same
  reference** (the cross-runner check is now part of the definition of
  done for snapshot changes).
- `bundle exec fastlane lint`, `test` and `snap` green locally.
- Reference PNG reviewed by eye before committing; no orphaned
  references left in `__Snapshots__/`.

### Follow-up generated (not resolved in this task)

- **Task 5 (CI):** confirm CLI-recorded references pass on the CI
  runner (same pinned simulator/OS); decide whether `snap` runs as a
  separate job or inside `test` (the lane builds the full scheme either
  way).
- **Sprint 2:** DesignSystem component suites adopt `.sizeThatFits`;
  new suites must be added to the `snap` lane's `only_testing` list;
  move to a `.xctestplan` when that list outgrows 2–3 entries.
- **Sprint 5:** dark mode / Dynamic Type snapshot variants (per plan).
- **Watch upstream:** if swift-snapshot-testing/Xcode fix `.device`
  safe-area fidelity, re-evaluate the layout ban for full-screen
  snapshots that genuinely need safe-area realism.
- Minor: the pinned device string (`"iPhone 17"`) is now repeated in
  the Fastfile (`test` + `snap`) — extract a constant next time the
  file is touched; the `snap` lane `desc` still references the old
  `docs/testing.md` filename (pre-rename) and needs the same touch.
