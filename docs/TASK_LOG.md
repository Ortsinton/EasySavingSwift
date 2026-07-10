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

---

## Task 5: GitHub Actions CI pipeline

**Branch/PR:** `0-5-ci-pipeline`, PR #4
**References:** ADR-009; closes follow-ups from tasks 0-3 (plugin trust,
SPM cache, README badge, retries decision) and 0-4 (snapshot references
vs. CI runner, snap-lane placement)

### Summary

Added `.github/workflows/ci.yml`: two jobs (`lint`, then `test` gated by
`needs: lint`) on a pinned `macos-26` runner with Xcode 26.6 selected via
`DEVELOPER_DIR`, Ruby pinned by a new `.ruby-version`, SPM caching keyed
on `Package.resolved`, cancel-in-progress concurrency, and an
xcresult-bearing artifact uploaded on test failure. Fastlane lanes gained
`result_bundle: true` and extracted constants (`DEVICE`, scheme, project
path). README got the CI badge; `lint.sh` / `format.sh` convenience
scripts landed at the repo root. Both open unknowns from 0-4 resolved
favorably on the first real run: xcodebuild needed no plugin-validation
skip flags, and the locally recorded snapshot references passed unchanged
on the runner. Branch protection and the dummy-PR evidence are completed
by the PR that lands this entry (see Follow-up).

### Decisions made

- **Runner: `macos-26` (preview) over GA `macos-15`, by pinned-environment
  necessity.** Verified against the `actions/runner-images` inventory:
  `macos-15` tops out at Xcode 26.3 / iOS 26.2 runtime; only `macos-26`
  ships Xcode 26.6 (17F113 — the exact local build) and the iOS 26.5
  runtime that `docs/TESTING.md` pins. The usual "prefer GA over beta"
  heuristic loses to the snapshot contract: a reference is only valid
  under the pinned environment, and CI must reproduce it, not dictate a
  downgrade. Label is explicit (`macos-26`), never `macos-latest` — a
  moving pointer is the anti-pin.
- **Xcode pinned via `DEVELOPER_DIR` env at workflow level** — no
  third-party setup action for what one environment variable does
  (same philosophy as ADR-007). Fails loudly if the image ever drops
  Xcode 26.6.
- **Triggers: `pull_request` + `push` on `main`.** The push trigger
  feeds the README badge (default-branch runs) and verifies `main`
  post-merge (semantic merge conflicts).
- **Job topology evolved twice during the task, deliberately:**
  started as a single `lint-build-test` job (motivated by per-job macOS
  setup cost); split into `lint` and `test` once the repo being public
  (free minutes) evaporated the cost argument — job granularity is
  signal granularity in the PR checks tab; then serialized with
  `needs: lint` (fail-fast: a lint failure skips the expensive test job;
  accepted cost: green runs pay lint latency before tests start). Jobs
  are named exactly after the fastlane lanes they run — one job, one
  lane, same vocabulary locally and in CI.
- **Cache keys are job-scoped** (`spm-lint-…` / `spm-test-…`): both jobs
  write different contents into `EasySavingKit/.build`, and Actions
  cache entries are immutable — a shared key would leave one job forever
  restoring the other's partial cache. `hashFiles('**/Package.resolved')`
  covers both lockfiles (the two-lockfile split from task 0-3).
- **`result_bundle: true` on `test` and `snap` lanes** so the
  `.xcresult` (which carries snapshot reference/actual/diff attachments)
  lands in `fastlane/test_output`, which the failure-only artifact step
  uploads. Without it, scan only emits html/junit reports — useless for
  diagnosing a pixel divergence on the runner.
- **`number_of_retries` deliberately rejected** (0-3 follow-up):
  automatic retries would mask exactly the snapshot nondeterminism the
  TESTING.md determinism policy exists to surface. Flakiness must stay
  visible; reconsider only with recurring infrastructure-failure data.
- **`DEVICE = "iPhone 17 (26.5)"`** — OS pinned explicitly because a bare
  device name lets fastlane pick the *highest* runtime on the machine
  (the runner ships 26.2/26.4/26.5). Also closes the 0-4 minor about the
  repeated device string; `ROOT_PROJECT_SCHEME` / `ROOT_PROJECT_PATH`
  extracted alongside.
- **`snap` stays a local-iteration lane; CI runs `test` only.** Resolves
  the 0-4 open question: the `test` lane runs the whole scheme unfiltered,
  so the snapshot suite already executes inside it — `snap`'s
  `only_testing` is a strict subset, and a separate CI job would pay a
  full runner spin-up to re-run it.
- **`.ruby-version` (4.0.5) added** — read by `ruby/setup-ruby`
  (`bundler-cache: true` installs the pinned bundle) and by rbenv/mise
  locally; closes the recurring system-Ruby-shadowing saga (0-3, 0-4).
- **Convenience scripts at repo root** (`lint.sh`, `format.sh`),
  executable, *not* referenced in the Xcode project (precedent: terminal
  shortcuts stay out of the navigator; config you edit — like `ci.yml` —
  may be referenced, with no target membership). `lint.sh` mirrors the
  lint lane verbatim (Fastfile stays canonical; sync noted in the script
  header). `format.sh` is deliberately lane-less: CI never rewrites code
  (0-3 decision), so write-mode formatting exists only as an explicit
  local action.
- **Branch-protection gotcha recorded:** a required check in *skipped*
  state counts as passing (GitHub semantics for `needs`/path-filtered
  jobs). Harmless here — `test` only skips when `lint` is red, which
  blocks the merge by itself — but "skipped ≠ verified" matters if a
  required job ever gains an `if:` condition.

### Problems / findings during implementation

- **The SPM plugin write sandbox demands both grants at once** (refines
  the 0-3 note): `--allow-writing-to-directory .` alone is rejected —
  the plugin manifest's own declared permission is only satisfied by
  `--allow-writing-to-package-directory`, while the generic flag covers
  app-target sources outside the package. Found empirically writing
  `format.sh`; neither flag alone suffices. Write mode also needs
  `--cache ignore` (the sandbox blocks `~/Library/Caches/` too).
- **First-run silence is not a hang.** "Testing started" with no output
  for ~6–10 min on the runner is the simulator's first boot on a fresh
  VM plus the serialized (`parallel_testing: false`) suite, dominated by
  the template UI tests (~87 s locally, 2–3× on the runner). The designed
  guard for a real hang is `timeout-minutes`, not manual judgment.
- **Live job logs are admin-gated on the API** (403 without repo-admin
  token) — mid-run diagnosis happens in the browser; the API serves
  step-level status/timings unauthenticated on public repos.
- **Plugin validation under xcodebuild: no issue.** `run_tests` passed
  with no `-skipPackagePluginValidation` — command plugins not attached
  to build targets are not fingerprint-validated. The skip flags stay
  out of the Fastfile (they are a security bypass with no justifying
  failure).

### Verification

- PR #4 ran the pipeline green **twice** (single-job topology
  `3aa75ee`, split topology `f7894e8`). Final-topology timings:
  `lint` 1 m 35 s total (fastlane step 1 m 04 s, uncached);
  `test` 13 m 49 s total (fastlane step 13 m 14 s: package tests +
  full app scheme incl. snapshot suite, all uncached).
- **Snapshots recorded locally passed on the runner unchanged** — the
  cross-runner determinism promised by the 0-4 layout policy (`.fixed`,
  no `.device`) now holds across machines, not just runners.
- Failure-artifact step correctly `skipped` on green runs; cache
  post-steps saved both job-scoped entries.
- `lint.sh` verified green (15 files, 0 violations); `format.sh`
  verified as a no-op on a clean tree (0/11 files, clean `git status`).

### Follow-up generated (not resolved in this task)

- **Branch protection + dummy-PR evidence close with the *next* PR** (the
  one landing this entry): protection on `main` (require PR, require
  `lint` and `test` checks, require up-to-date branches) must be
  configured *before* opening it, so the docs-only PR runs the full
  pipeline against active protection — that PR is the ticket's evidence.
  From then on, the job names `lint`/`test` are frozen contracts
  (renaming one without updating the protection rule blocks all merges).
  **Correction (task 0-6):** it did not happen in that order. PR #5 was
  merged before protection existed; protection was configured right
  after, as a repository **ruleset** (`lint-test-needed`), not a classic
  rule — see the 0-6 entry for the mechanism choice and the
  enforcement-disabled pitfall found on the way. PR #5 stands as the
  full-pipeline-on-a-trivial-PR evidence; the first merge actually
  *gated* by the active ruleset is task 0-6's own PR.
- **Template UI tests cost real CI minutes for zero coverage** (~87 s
  locally, 2–3× on the runner, every PR): replace with the minimal
  ADR-008 happy-path XCUITest when real UI lands (Sprint 2), or delete
  earlier if they get in the way.
- **Cache effectiveness unmeasured:** first runs were all misses by
  construction (new keys). Check hit-rate and timing delta on the next
  PR; if `test` doesn't improve, consider whether `EasySavingKit/.build`
  is the right path set for the xcodebuild-driven job.
- **Runner image is a preview label:** when `macos-26` goes GA (or the
  image drops Xcode 26.6), the pin must be revisited together with the
  snapshot environment — any change re-records the suite deliberately
  (TESTING.md policy).
- Minor, resolved in the same PR as this entry: `docs/TESTING.md` now
  pins Xcode 26.6 (17F113) explicitly instead of "26.x".

---

## Task 6: Seed TASK_LOG and close Sprint 0

**Branch/PR:** `0-6-close-sprint-0`
**References:** CLAUDE.md workflow, ADR-011; closes the 0-5 follow-up
(branch-protection correction)

### Summary

Sprint 0 closure. The ticket assumed the TASK_LOG would be written
retrospectively at sprint end; in practice it was built incrementally,
one entry per task — so this task reduced to an audit plus the formal
handoff. Audited entries 1–5 against the "every structure decision
recorded as precedent" criterion: complete (see Verification). Corrected
the 0-5 entry to match what actually happened with branch protection,
recorded the ruleset decision, added the Sprint 1 ticket text to
`docs/SPRINT_PLAN.md`, and drafted the four Sprint 1 cards in Trello.
This task's PR is the first merge gated by the active ruleset — the
enforcement evidence 0-5 left pending.

### Decisions made

- **TASK_LOG policy formalized: entries are written when a task closes,
  not at sprint end.** The incremental log already paid for itself
  (0-4's investigation notes fed 0-5's design directly); the ticket's
  retrospective framing is superseded.
- **Branch protection is a repository ruleset, not a classic rule.**
  Rulesets are the current mechanism (classic is legacy): readable by
  anyone with repo read access, stackable, with an enforcement status
  (Active/Evaluate/Disabled). Configuration of record: target
  `~DEFAULT_BRANCH`; require PR (0 approvals); required status checks
  `lint` + `test` with strict up-to-date policy; deletions and force
  pushes blocked; **empty bypass list** — not even admins skip the
  checks, which is what "green by construction" means.
- **Sprint plans keep living in the repo:** Sprint 1 tickets recorded in
  `docs/SPRINT_PLAN.md` following the Sprint 0 precedent — Trello is the
  operational board, the repo is the memory.
- **Sprint 1 sliced into four linearly dependent cards** (1-1 domain
  models → 1-2 protocols + use cases → 1-3 `@Model` + mappers → 1-4
  `ModelActor` repositories + integration tests). Kept 1-1 and 1-2
  separate despite their size — the model/use-case boundary deserves its
  own review. No buffer card for minor technical follow-ups; they
  resolve in passing or wait.

### Problems / findings during implementation

- **The ruleset UI defaults Enforcement status to "Disabled".** The rule
  was created correctly and was protecting nothing; caught only because
  the state was verified via API (`/rules/branches/main` returned `[]`)
  instead of trusting the UI flow. Same session, second instance of the
  lesson: verify externally observable state, not the memory of having
  configured it.
- **Verifying rulesets needs the rules endpoints.** The legacy
  `protected` field on the branches API only reflects classic rules
  (stayed `false` throughout); `/rules/branches/{branch}` lists the
  effective rules and is readable unauthenticated on public repos.

### Verification

- Precedent audit over entries 1–5, all recorded: build settings at
  project level (0-1); docs visible in Xcode without target membership
  (0-1); package at repo root without `Packages/` nesting (0-2);
  `S-N-short-name` branches (0-2); plugins declared in
  `EasySavingKit/Package.swift` (0-3); two tracked lockfiles (0-3);
  single `.swiftlint.yml` with boundary `custom_rules` (0-3); snapshot
  suites under `EasySavingTests/Snapshots/` with committed
  `__Snapshots__/` (0-4); SCREAMING_CASE repo docs (0-4); convenience
  scripts at repo root, outside the Xcode project (0-5); CI job names
  mirroring fastlane lane names (0-5).
- Active rules on `main` verified via API after activation: PR required
  (0 approvals), required checks `lint` + `test` (strict), deletion and
  force-push blocked.
- This PR merging is itself the final verification: merge button gated
  on both checks under the active ruleset.

### Follow-up — Sprint 1 handoff

Deferred items carried into Sprint 1, consolidated from entries 0-2..0-5:

- **1-1:** delete `CorePlaceholder` and its `ContentView` usage;
  **1-3:** delete `DataPlaceholder` and the `linkProof` wiring in
  `EasySavingApp` (0-2 follow-up, split by half).
- **First cache-effectiveness data point** (0-5): compare `lint`/`test`
  job times of this task's PR against the uncached baseline
  (1 m 35 s / 13 m 49 s); revisit the cached path set if `test` doesn't
  improve.
- Standing deferrals, unchanged owners: `SwiftLintBuildToolPlugin` +
  pre-commit hook (0-3, by decision); DesignSystem snapshot suites with
  `.sizeThatFits` and `.xctestplan` migration (0-4 → Sprint 2); template
  UI tests replaced by the minimal ADR-008 happy path (0-5 → Sprint 2);
  dark mode / Dynamic Type snapshot variants (Sprint 5); watch
  `macos-26` GA transition and the upstream `.device` safe-area fix.
- Sprint 1 cards live in Trello "To Do"; ticket text of record in
  `docs/SPRINT_PLAN.md`.

---

## Task 1-1: Domain models — Transaction, Category, Money

**Branch/PR:** `1-1-domain-models`
**References:** ADR-002, ADR-010; closes the 0-2 follow-up (Core half:
`CorePlaceholder` deletion)

### Summary

Materialized ADR-010 in `EasySavingCore`: `Money` (Int minor units +
ISO 4217 code, arithmetic operators with same-currency preconditions),
`Category` and `Transaction` as public `Sendable` structs with nested
typed IDs over client-generated UUIDs and relationships by id
(`Transaction.categoryID`). `Transaction`'s init normalizes the
day-granular business date through an **injected** `Calendar`
(`startOfDay`), leaving `createdAt` untouched as a raw instant for stable
ordering. Parameterized Swift Testing suites cover `Money` arithmetic
edge cases (including `Int.max`/`Int.min` borders) and date
normalization, including the Madrid spring-forward DST boundary and the
23-hour-day proof (82 800 s between consecutive normalized midnights).
Deleted `CorePlaceholder` + its test + its `ContentView` usage;
re-recorded the placeholder snapshot. Getting the new test idioms past
SwiftLint produced a two-pass lint architecture (see Decisions).

### Decisions made

- **Folder precedent (per the emergent-structure policy):**
  `Sources/EasySavingCore/Domain/Models/`; `Domain/Repositories/` and
  `Domain/UseCases/` arrive in 1-2, `Presentation/` in Sprint 2. The cut
  is by conceptual layer, not by feature (ADR-002 proportionality).
  Test folders mirror the source tree
  (`Tests/EasySavingCoreTests/Domain/Models/`).
- **`Decimal` was evaluated and rejected for `Money`** (the ADR-010
  Int-minor-units rule survives re-examination without its KMP origins):
  base-10 `Decimal` fixes `Double`'s representation problem but allows
  fractional cents (invalid states), silently defers rounding decisions,
  and its `ExpressibleByFloatLiteral` init routes through `Double`
  (precision trap). Int minor units make invalid states unrepresentable
  and match fintech convention. `Decimal` remains the right tool *at the
  edges*: UI parsing/formatting and exchange-rate math (Sprint 4), where
  conversions go Int → Decimal → explicit rounding → Int.
- **Mixed-currency arithmetic is a `precondition`, not `throws`:** in a
  single-currency MVP it is a programmer error (fail fast), not a
  recoverable condition. Multiplication is money × `Int` scalar only —
  money × money is dimensionally meaningless (cents²).
- **Sign lives in `Transaction.Kind`** (`.income`/`.expense`, nested
  enum); amounts stay positive. Amount validation (> 0) is business
  logic and lands in `AddTransactionUseCase` (1-2), not in the model.
- **`note: String?`** — absence of a note is `nil`, not `""`.
- **ID pattern:** nested `struct ID: Sendable, Hashable` with
  `rawValue: UUID` and `init(rawValue: UUID = UUID())` (the default *is*
  the "client-generated" rule). `type_name` lint rule excludes `ID`
  globally — the stdlib's `Identifiable` consecrates the name.
- **Package tests import the public surface without `@testable`** —
  tests act as the first real client of the API (this immediately
  exposed the internal-memberwise-init gaps). `@testable` requires
  case-by-case justification.
- **Expected values in test tables are human-validated literals, never
  recomputed** with the operation under test (tautology risk); dates are
  built from literal `DateComponents` through the pinned calendar, never
  via the API under test.
- **Test fixtures:** fixed `Calendar` (gregorian, `Europe/Madrid`) as a
  `static let` — never `Calendar.current`/`Date()` in domain tests
  (machine-dependent → CI divergence); test-data builder
  (`makeTransaction`) with static-helper defaults so each test states
  only what it cares about (static because default arguments cannot
  touch instance members).
- **Lint architecture: two SwiftLint passes.** Production paths lint
  against the root `.swiftlint.yml`; test paths against a **standalone**
  `EasySavingKit/Tests/.swiftlint.yml` that relaxes exactly three rules
  whose purpose is protecting production API: `large_tuple` and
  single-letter `identifier_name` (parameterized-table idioms) and
  `force_unwrapping` (in fixture helpers, nil means broken test
  infrastructure — crashing is correct). `line_length` deliberately
  stays. The config is standalone *by exhaustion*, all verified
  empirically with a canary file: nested-config discovery is disabled
  whenever `--config` is passed; `child_config` merges globally (canary
  in `Sources/` went unflagged); `parent_config` merges `excluded`
  additively, so inheriting the root would exclude the very tests the
  pass exists to lint (false green caught by counting linted files, not
  trusting exit codes). Manual sync with the root config is documented
  in both files.

### Problems / findings during implementation

- **`Sendable` inference switches off at `public`.** Non-public structs
  get implicit `Sendable`; the `public` pass silently dropped it from
  `Category` until reviewed. For public types, sendability is an API
  contract that must be declared.
- **The only defects of the task were born in untested code, twice.**
  `Money.*` was written implementation-first both times and was wrong
  both times (first `Money × Money` conceptually, then a body that
  ignored the scalar — Swift emits no unused-parameter warning). Every
  test-first operator came out correct. The TDD guardrail, demonstrated
  on home turf.
- **Deleting `CorePlaceholder` exposed a hidden dependency:**
  `DataPlaceholder` consumed it to prove the Data → Core arrow (0-2), so
  the Core-half deletion had to touch one line in `EasySavingData`
  ahead of 1-3's full cleanup; snapshot re-recorded accordingly.
- **SwiftLint plugin re-confirmed the 0-3 finding** (package paths are
  appended to every invocation), which is why both configs need
  mirror-image `excluded` entries (in several spellings — path
  resolution differs between config-file dir and the plugin's working
  dir).
- **Non-interactive shells need an explicit UTF-8 locale for fastlane:**
  `xcpretty`/scan crash with `invalid byte sequence in US-ASCII` parsing
  xcodebuild output otherwise (fastlane's startup warning is the tell).
  Worth remembering for any future scripted/CI-adjacent invocation:
  prefix with `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8`.

### Verification

- `swift test` from the package: 10 tests in 3 suites green
  (`MoneyTests` 5 parameterized tables, `TransactionTests` 3 contracts,
  Data placeholder).
- `./lint.sh`: 0 violations in both passes (production 11 files, tests
  11 files — `MoneyTests`/`TransactionTests` confirmed present in the
  test pass after the false-green incident).
- `bundle exec fastlane test`: green (package + app scheme incl. the
  re-recorded snapshot), 70 s locally.
- Boundary intact: no new imports in Core beyond Foundation.

### Follow-up generated (not resolved in this task)

- **1-2:** amount-positivity validation in `AddTransactionUseCase`;
  repository protocols + use cases get `Domain/Repositories/` and
  `Domain/UseCases/` per the folder precedent.
- **1-3:** `DataPlaceholder` + `linkProof` deletion (Data half of the
  0-2 follow-up), now one line smaller.
- **Optional, exit tests:** `precondition` violations (mixed-currency
  arithmetic) are untestable without Swift Testing exit tests
  (`#expect(processExitsWith:)`); adopt if/when the toolchain makes them
  cheap on this setup.
- **Lint config duplication is hand-maintained** (root ↔ test config):
  revisit if SwiftLint ever ships directory-scoped composition that
  survives `--config`.
- `Money` deliberately ships without `Comparable` and without `Int *
  Money` (commutative overload); add either when a real call site
  demands it, not before.

---

## Task 1-2: Repository protocols and first use cases

**Branch/PR:** `1-2-repositories-and-use-cases`
**References:** ADR-002, ADR-007, ADR-008; closes the 1-1 follow-up
(amount-positivity validation lives in `AddTransactionUseCase`)

### Summary

Added the persistence-agnostic seam promised by ADR-007:
`TransactionRepository` and `CategoryRepository` protocols in Core
(async/throws, expressed exclusively in domain types) plus the first three
use cases — `AddTransactionUseCase` (owning the business validation),
`GetTransactionsUseCase`, `DeleteTransactionUseCase` — unit-tested against
hand-written in-memory fakes, zero mocking frameworks. Folder precedents:
`Domain/Repositories/` and `Domain/UseCases/` in sources; `Fakes/` and
`Support/` on the test side (suite infrastructure, deliberately no source
mirror). The Core boundary stays green: Foundation-only imports.

### Decisions made

- **Repository protocol shape:** `public protocol X: Sendable` with
  everything `async throws`. `Sendable` is part of the contract so types
  holding a repository can be `Sendable` themselves (the 1-4 `ModelActor`
  implementations cross isolation boundaries); `async` applies even to
  reads (adding it later breaks every call site). Reads are named as noun
  phrases (`transactions()`, not `fetchTransactions()`) per the Swift API
  Design Guidelines. `save` is documented as upsert — the doc comment is
  the only spec the 1-4 implementer gets. `delete` takes `Transaction.ID`
  (relationships-by-id, ADR-010). `category(for:)` returns `Optional`:
  absence is a query result, not an error.
- **Use case canonical form (precedent):** `public struct` conforming to
  `Sendable`, dependencies stored as `any` existentials injected through
  the initializer, a single `execute()` method. `callAsFunction` rejected
  (call-site elegance vs. greppability). First argument unlabeled when it
  is the obvious direct object (`execute(_ transaction:)`). Explicit `any`
  everywhere, parameters included; existentials over generics at injection
  seams — a generic parameter would infect ViewModel and composition-root
  signatures for no measurable win.
- **Business verbs, not storage verbs:** `AddTransactionUseCase`, not
  `Save…` — use cases speak the user's language, repositories the
  store's. `GetTransactionsUseCase` is plural: it returns the list.
- **Error design:** a companion top-level enum in the use case's own file
  (`AddTransactionError: Error, Equatable`; the "one type per file" rule
  admits the contract companion, same as nested `ID`s). `Equatable` is
  for tests (`#expect(throws:)` compares case + payload);
  `categoryNotFound(Category.ID)` carries the offending ID. Signature
  stays untyped `throws`: typed throws would force wrapping repository
  errors into the enum — deferred until a call site wants exhaustive
  handling. Boundary recorded: invalid user input (amount ≤ 0) is an
  expected, recoverable condition → `throws`; `Money`'s mixed-currency
  `precondition` (1-1) remains programmer error → trap.
- **Fakes: form follows state.** `FakeTransactionRepository` is an
  `actor` (mutable `saved` array accessed across tasks);
  `FakeCategoryRepository` is a plain struct (immutable seeded state —
  nothing to protect, no serialization to pay for). Fakes implement the
  *documented* contract (upsert), not just the signature. State-based
  testing over interaction-based: assert on repository contents, never on
  call recording — the reason no mocking framework is needed.
- **Shared fixtures:** `Support/Fixtures.swift`, extracted from
  `TransactionTests` when the second consumer appeared (rule of two). A
  caseless enum as namespace — non-instantiable by construction, zero
  ceremony. Builders gained defaulted parameters so each test states only
  what it cares about. `@testable` stays banned — which immediately
  caught a missing `public init` on `Category` (see findings).
- **Assertion policy (precedent):** assert *content equality*, not counts
  — validate every test against the "evil implementation" heuristic
  (would it fail if `delete` removed the wrong row, or `get` returned
  fabricated data?). Error-path tests also assert no partial writes.
  `#expect(throws: Never.self)` is reserved for tests whose entire
  contract is "does not throw" (the delete no-op); happy paths just `try`
  and assert state.

### Problems / findings during implementation

- **`Category` is ambiguous in the test target — Objective-C's fault.**
  The ObjectiveC runtime module declares `typealias Category =
  OpaquePointer` (Obj-C categories) and Foundation re-exports it on
  Darwin. Inside `EasySavingCore` the local declaration outranks imports;
  in the test target both candidates are imports, so *type-position*
  lookup (`categoryID: Category.ID`) ties and errors, while
  *expression-position* (`Category.ID()`) disambiguates by member lookup
  (`OpaquePointer` has no `.ID`). Fix: qualify the two type positions in
  `Fixtures.swift`. Escalation if the clash spreads (it will, in the app
  target): one local `typealias Category = EasySavingCore.Category` per
  target — local declarations beat imports.
- **actor ≠ async, caught live.** A draft made the test suite an `actor`
  to "gain access" to the fake actor's state. Isolation is per-instance:
  being an actor grants nothing about *other* actors; the ability to
  `await` comes from the function being `async`. Suites stay structs with
  async test functions.
- **The internal-memberwise-init lesson (0-2) recurred:** constructing
  `Category` from the test target required adding its explicit
  `public init`. Same class of finding, third occurrence: `public` on the
  type is a decision the members must accompany.
- **Weak assertions were the review churn of the task:** count-based
  checks and tests that passed against empty/evil implementations
  (delete-without-selectivity, get-without-content). The assertion policy
  above is the distilled takeaway.
- **The relaxed test lint config earned its keep:** `line_length` (kept
  deliberately in 1-1) and `empty_count` flagged five real cleanups in
  the new tests; each violation reported twice (the 0-3 double-linting
  cosmetic, still accepted).

### Verification

- `swift test` from the package: 17 tests in 6 suites, green. Suites run
  in parallel by default; safe because every test builds its own fakes —
  zero shared state.
- `./lint.sh`: 0 violations in both passes; boundary rules
  (`core_boundary`) green — no new imports in Core beyond Foundation
  (verified also by grep).
- `bundle exec fastlane test`: green (package + app scheme incl.
  snapshot suite).

### Follow-up generated (not resolved in this task)

- **1-3:** SwiftData `@Model` classes + mappers; delete `DataPlaceholder`
  and the `linkProof` wiring (Data half of the 0-2 cleanup).
- **1-4:** implement both protocols as `ModelActor` repositories against
  an in-memory `ModelContainer`. The upsert doc comment on `save` is the
  contract to honor; the fakes' behavior is the executable spec to match.
- Typed throws on `execute` — revisit only when a call site needs
  exhaustive error handling.
- Per-target `typealias Category = EasySavingCore.Category` if the
  ObjectiveC clash spreads beyond the two qualified sites in
  `Fixtures.swift`.
- Template file headers went stale twice during renames this task;
  dropping them entirely was floated and deferred — decide next time one
  lies.

---

## Task 1-3: SwiftData @Model classes and mappers

**Branch/PR:** `1-3-SwiftData-models`
**References:** ADR-005, ADR-010; closes the 0-2 follow-up (Data half:
`DataPlaceholder` + `linkProof` wiring deleted); supersedes the 0-1
commit-message decision (see Decisions)

### Summary

Added the persistence representation in `EasySavingData`:
`TransactionModel` and `CategoryModel` as internal `final` `@Model`
classes under `Persistence/Models/`, with bidirectional mappers as
extensions under `Persistence/Mappers/` (`Type+Mapping.swift` files) and
a `MappingError` enum for the fallible direction. The central design
outcome: **mapping is not ingestion** — mappers restore persisted state
verbatim and never re-run domain policy, which forced a second, explicit
rehydration path into `Transaction` (Core). Round-trip unit tests cover
id/date/money/note fidelity plus the unknown-kind error path. The app
target no longer imports `EasySavingData` at all; `ContentView` is back
to a plain placeholder and its snapshot was re-recorded. `swift build`
for the host Mac surfaced a missing macOS platform declaration in
`Package.swift` (see Problems).

### Decisions made

- **Folder precedents:** `Sources/EasySavingData/Persistence/Models/`
  and `Persistence/Mappers/` — `Persistence/` as a sibling of the future
  `Networking/` (ADR-006) so the target's layout narrates its
  architecture. Test tree mirrors it
  (`Tests/EasySavingDataTests/Persistence/Mappers/`). Mapper files are
  extensions named `Type+Topic.swift` (the Swift convention; one-type-
  per-file is not violated — no new type lives there).
- **`@Model` classes are `internal final`, no explicit `PersistentModel`
  conformance** — the macro adds it; writing it by hand is redundant.
  `internal` is the ADR-005 boundary made real: persistence types never
  become package API.
- **The schema stays primitive.** Typed IDs flatten to `UUID` columns
  (never `String` — no parse-failure path on read); `Money` flattens to
  `amountMinorUnits: Int` + `currencyCode: String` (a value object
  becomes columns; the mapper recomposes it); `Transaction.Kind`
  persists as a `String` (`"income"`/`"expense"`).
- **Kind as String, and why not the alternatives:** an `Int` raw value
  is positional — reordering/inserting enum cases silently changes the
  meaning of stored rows; a `Codable` domain enum stored directly makes
  the on-disk format an opaque encoding coupled to domain case names
  (renaming a case in Core would corrupt existing stores). The disk
  strings live as private constants (`KindValue`) in the mapper file —
  the single source of truth both switch directions share. An explicit
  switch was preferred over a raw-value enum precisely to keep domain
  names and disk format independently renameable.
- **Mapping is not ingestion (the Calendar trap).** `Transaction`'s
  canonical init normalizes the business date via injected `Calendar` —
  that is *ingest-time* policy. Re-running it on read would let a device
  timezone change silently mutate persisted business dates (startOfDay
  over an already-normalized date is only idempotent under the same
  calendar). Resolution: a second public init in Core
  (`normalizedDate:`) that applies no normalization, documented as
  rehydration-only. The contract is documentary — `Date` cannot express
  "already normalized"; a compile-time `DayDate` type is recorded as
  deliberate debt, not adopted.
- **Model→domain is the partial direction and throws.** Unknown `kind`
  on disk is external input (a future app version, a migration bug),
  not an in-process programmer error — so `MappingError` (top-level
  enum, `Equatable`, own file) rather than a precondition; the 1-2
  error boundary reaffirmed. Domain→model is total and cannot fail.
- **`@testable import EasySavingData` — the first justified use.** The
  1-1 rule ("tests exercise public API, no `@testable`") assumes the
  tested surface *should* be public. Persistence types are internal by
  architectural decision; making them public to test them would destroy
  the boundary being tested. Case-by-case justification recorded as
  precedent. Data tests grew their own minimal `Fixtures` (test targets
  cannot import each other; rule of two not met across targets).
- **Round-trip test policy:** one `Equatable` identity assert
  (domain → model → domain == original) is the future-proof verdict —
  field-by-field domain asserts go stale when fields are added. Its
  blind spot: two *symmetric* mapper bugs cancel out — so the
  domain→model direction asserts columns directly against hand-written
  literals (`"income"`, never the `KindValue` constants — the test pins
  the disk format; referencing the constants would be tautological).
  Fixture dates are literal Madrid-midnight values, which makes the
  identity assert double as the regression test for the Calendar trap
  (a re-normalizing mapper fails on any non-Madrid machine, CI
  included).
- **`platforms` gained `.macOS(.v14)`** in `Package.swift`: the list is
  *per-platform minimums when built for that platform*, not "supported
  platforms". `swift build`/`swift test` compile for the host Mac, and
  SwiftData requires macOS 14 — without the entry, SPM assumes the
  toolchain's historic minimum and availability checking fails. Keeps
  the no-Xcode package workflow alive (a 1-4 acceptance criterion).
- **Commit-message convention changed (supersedes 0-1):** descriptive
  messages prefixed with the task id (`1-3 Added models and mappers`),
  no Conventional Commits prefixes. CLAUDE.md updated; the 0-1 entry
  stays as written (historical record, per the 0-2 precedent).
- **Template file headers survive another sprint:** one lied again
  (`Napping.swift` after a rename); dropping them was re-floated and
  remains deferred.

### Problems / findings during implementation

- **`swift build` broke the moment `@Model` landed:**
  `'_PersistedProperty()' is only available in macOS 14 or newer`. First
  real proof that the CLI builds the package for the host platform, and
  that `platforms:` had only ever declared the iOS floor. Fixed as per
  Decisions.
- **The Obj-C `Category` clash spread to `EasySavingDataTests`,** as
  1-2 predicted: `Fixtures.swift` needed `EasySavingCore.Category`
  qualifications in type positions. Escalation path (per-target
  `typealias`) still on the shelf.
- **The unused-import lesson (0-1) recurred in the app target:**
  deleting `DataPlaceholder` usage left `import EasySavingData` behind,
  compiling silently. Caught by grep in review — Swift still emits no
  diagnostic for unused imports.
- **Review churn worth remembering:** `MappingError` was first written
  as a class imitating enum cases (losing `Equatable` payload
  comparison); a `do { } catch { throw error }` no-op wrapped
  `toDomain()`; the round-trip test initially asserted field-by-field
  instead of by identity, reimplemented the kind mapping inside
  `Fixtures` (a tautology one step removed), and used `Date()` despite
  the 1-1 machine-independence precedent. Each is the negative print of
  a Decision above.

### Verification

- `swift test` from the package: 20 tests in 7 suites, green (round-trip
  parameterized over kind × note-nil, column pinning, unknown-kind error
  case, date-preservation regression).
- `./lint.sh`: 0 violations in 27 files; `data_boundary` green
  (acceptance criterion).
- `bundle exec fastlane test`: green — package + app scheme including
  the re-recorded placeholder snapshot.
- No `import EasySavingData` anywhere in the app target (grep).

### Follow-up generated (not resolved in this task)

- **1-4:** implement the `ModelActor` repositories over these models.
  Upsert (`save`'s documented contract) must match on the *business*
  `id` column, not `persistentModelID` — and will want a uniqueness
  guarantee on `id` (`#Unique`/`@Attribute(.unique)`), deliberately not
  added here where no fetch path exists yet to exercise it.
- `DayDate` (compile-time "day-normalized" guarantee) recorded as
  conscious debt; revisit if the documentary contract on
  `init(normalizedDate:)` ever gets misused.
- `Transaction`'s two inits duplicate their assignment bodies; the
  canonical one could delegate to the rehydration one
  (single assignment path) — suggested in review, not adopted, harmless.
- Per-target `typealias Category = EasySavingCore.Category` if the
  Obj-C clash reaches a third site (now at two: Core tests fixtures,
  Data tests fixtures).
- File headers: still kept, still occasionally lying — the standing
  offer to strip them (SwiftFormat `--header strip`) remains open.
