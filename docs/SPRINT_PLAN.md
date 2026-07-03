# EasySaving iOS — Sprint Plan & Sprint 0 Backlog

Planning horizon: technical interview in ~1–2 weeks; ~20–25h/week
availability. Sprints are short (3–4 working days) so that by interview
date Sprints 0–2 are done — per ADR-011, those alone cover the majority of
likely interview themes (modularity, MVVM-C, Swift Concurrency, testing,
CI). Everything after the interview keeps working as ongoing practice.

---

## Sprint overview (coarse goals)

**Sprint 0 — Walking skeleton (days 1–2).**
Goal: an empty but *real* project. Two-target package with the boundary
verified, linters, Fastlane lanes, snapshot infra, CI green on a PR.
Definition of done: a trivial PR runs the full pipeline and merges green.

**Sprint 1 — Core + persistence (days 3–5).**
Goal: the domain exists and survives a restart. Domain models
(`Transaction`, `Category`, `Money`), repository protocols, first use
cases, SwiftData `@Model`s + mappers + `ModelActor` repositories, unit
tests in Core and integration tests against an in-memory container.
Definition of done: `AddTransaction` → relaunch → data still there,
proven by tests, no UI yet.

**Sprint 2 — First features with MVVM-C (days 6–9).**
Goal: the app is usable. Transaction list + transaction form (create/edit/
delete), coordinator with `Route` enum and `NavigationPath`, first
DesignSystem components, ViewModel unit tests + first real snapshots.
Definition of done: full CRUD flow on device/simulator, navigation owned
by the coordinator, screens snapshot-tested.

--- interview readiness line ---

**Sprint 3 — Analytics.**
Goal: aggregation use cases (by category, monthly trend) computed in
Core, rendered with Swift Charts. Parameterized Swift Testing cases for
the aggregation logic (edge cases: empty months, single category, DST
boundaries via injected Calendar).

**Sprint 4 — Networking: exchange rates.**
Goal: the full ADR-006 checklist — hand-rolled async/await `HTTPClient`,
typed endpoints, error taxonomy, retry with backoff, SwiftData cache with
stale-badge degradation. Tests against a stubbed client (no network in CI).

**Sprint 5 — Polish & portfolio surface.**
Goal: snapshot suite extended (dark mode, Dynamic Type variants),
VoiceOver pass, README with screenshots/gifs and an architecture summary
linking the ADRs. Optional stretch: deep-link demo through the coordinator.

---

## Sprint 0 — Trello tickets

Format per card: Title / Objective / Acceptance criteria / References.
Suggested board flow unchanged: To Do → Doing → Done, one branch per card
(`task-N-short-name`).

---

### Task 1 — Create Xcode project with Swift 6 strict concurrency

**Objective:** Bootstrap the `EasySaving` app project with the
non-negotiable build settings from day one, so no code is ever written
under laxer rules.

**Acceptance criteria:**
- New SwiftUI app project `EasySaving`, deployment target iOS 17.0.
- Swift language mode = Swift 6; strict concurrency = complete. Both
  visible in build settings and committed.
- App builds and runs on simulator showing a placeholder view.
- `.gitignore` appropriate for Xcode (DerivedData, xcuserdata, etc.).
- Initial commit on `main`; repo pushed with `docs/ADR.md` and
  `CLAUDE.md` included, old KMP docs moved to `docs/archive/`.

**References:** ADR-001, ADR-011.

---

### Task 2 — Create EasySavingKit package and verify the module boundary

**Objective:** Materialize the ADR-002 architecture: one local SPM package
with `EasySavingCore` and `EasySavingData` targets, wired into the app,
with the dependency direction proven by the compiler.

**Acceptance criteria:**
- Local package `EasySavingKit` with targets `EasySavingCore` (no project
  dependencies) and `EasySavingData` (depends on Core), plus test targets
  `EasySavingCoreTests` and `EasySavingDataTests` (Swift Testing).
- Each source target contains one public placeholder type consumed by the
  app's placeholder view (proves linking end-to-end).
- **Boundary check performed and documented in the TASK_LOG entry:** a
  deliberate `import SwiftUI` added inside Core fails the build; removed
  afterwards. (SwiftData ships with the platform, so also verify Core has
  no SwiftData import anywhere — grep is acceptable.)
- One trivial green `@Test` in each test target, runnable via
  `swift test` / Xcode.

**References:** ADR-002, ADR-008.

---

### Task 3 — SwiftLint + SwiftFormat + Fastlane lanes

**Objective:** Make code style and quality checks a command, identical
locally and in CI, before any real code exists.

**Acceptance criteria:**
- `.swiftlint.yml` (strict: warnings as errors in CI profile) and
  `.swiftformat` committed, with a short comment block in each explaining
  the 3–4 most opinionated choices.
- Fastlane installed with lanes: `lint` (SwiftLint + SwiftFormat check),
  `test` (build + package tests + app tests), `snap` (snapshot tests
  only). Lanes documented in README.
- Running `bundle exec fastlane lint` and `... test` locally passes.
- Placeholder code reformatted/fixed so everything is green.

**References:** ADR-009.

---

### Task 4 — Snapshot testing infrastructure

**Objective:** Set up `swift-snapshot-testing` and pin the rendering
environment while screens are still trivial, so snapshot flakiness is
solved before it can block feature work.

**Acceptance criteria:**
- `swift-snapshot-testing` added (app test target only) — the only
  third-party dependency allowed without a new ADR.
- One snapshot test of the placeholder view, pinned to an explicit device
  config + OS appearance; reference image committed.
- Re-running the test locally is deterministic (no diff on second run).
- Short `docs/testing.md` note (or TASK_LOG entry) on how to record vs
  verify snapshots, and the pinned simulator the team must use.

**References:** ADR-008.

---

### Task 5 — GitHub Actions CI pipeline

**Objective:** Every PR proves lint, build and all test levels on a pinned
environment; `main` stays green by construction.

**Acceptance criteria:**
- `.github/workflows/ci.yml` triggered on PRs to `main`: Fastlane `lint`
  → build → package tests (Core + Data) → app tests including the
  snapshot, on a pinned macOS runner image, Xcode version and simulator.
- SPM caching keyed on `Package.resolved`; concurrency group cancels
  superseded runs.
- Branch protection on `main`: PR + green pipeline required.
- Evidence: one dummy PR (e.g. README touch) run through the full
  pipeline and merged green.

**References:** ADR-009.

---

### Task 6 — Seed TASK_LOG and close Sprint 0

**Objective:** Start the project's memory: the TASK_LOG is the source of
truth between Claude Code sessions (per CLAUDE.md), so it must exist with
the sprint's real history, including the structure decisions made ticket
by ticket.

**Acceptance criteria:**
- `docs/TASK_LOG.md` created with one entry per Sprint 0 task in the
  agreed format (Summary / Decisions / Problems / Follow-up), written
  retrospectively from the actual PRs.
- Every folder/file-location decision taken during Sprint 0 is recorded
  as precedent (emergent-structure policy from CLAUDE.md).
- Follow-up section lists anything deferred into Sprint 1.
- Sprint 1 cards drafted in Trello "To Do" (titles + objectives at
  minimum) based on the Sprint 1 goal above.

**References:** CLAUDE.md workflow, ADR-011.
