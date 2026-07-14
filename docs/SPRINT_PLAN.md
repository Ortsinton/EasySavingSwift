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
(`S-N-short-name`, sprint-first numbering — see CLAUDE.md workflow).

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

---

## Sprint 1 — Trello tickets

Drafted at Sprint 0 closure (task 0-6). Four linearly dependent cards:
domain vocabulary first, then the persistence-agnostic seam, then the
SwiftData representation, then the actor-isolated implementations that
prove the sprint goal ("the domain exists and survives a restart") —
no UI anywhere in the sprint.

---

### Task 1 — Domain models: Transaction, Category, Money

**Objective:** Materialize ADR-010 in `EasySavingCore`: the domain
vocabulary as `Sendable` value types, with unit tests proving the
conventions rather than just stating them.

**Acceptance criteria:**
- `Transaction`, `Category` and `Money` structs: `Sendable`, `Equatable`,
  `Identifiable` where applicable; nested `struct ID: Hashable` typed
  identifiers over client-generated UUIDs; relationships by id
  (`Transaction.categoryID`), never embedded objects.
- `Money` wraps an `Int` amount in minor units plus a currency code. No
  `Double` anywhere in the domain; no formatting logic (that is a UI-edge
  concern per ADR-010).
- Day-granular business dates normalized through an **injected**
  `Calendar`; explicit `createdAt: Date` for stable ordering.
- Parameterized Swift Testing suites for `Money` arithmetic edge cases
  and date normalization (including one DST-boundary case through the
  injected calendar).
- `CorePlaceholder` and its `ContentView` usage deleted (0-2 follow-up,
  Core half).
- Folder layout inside `EasySavingCore` proposed with the task and
  recorded in the TASK_LOG entry as precedent.

**References:** ADR-002, ADR-010.

---

### Task 2 — Repository protocols and first use cases

**Objective:** Define the persistence-agnostic seam (repository
protocols) and the first business operations as use cases, unit-tested
against hand-written fakes — the testable architecture ADR-007 promises,
demonstrated without a single framework.

**Acceptance criteria:**
- `TransactionRepository` and `CategoryRepository` protocols in Core:
  async, expressed exclusively in domain types.
- Minimal use-case set: `AddTransactionUseCase` (business validation
  lives here — never in future ViewModels), `GetTransactionsUseCase`,
  `DeleteTransactionUseCase`. Naming/shape recorded as precedent.
- Unit tests with in-memory fake repositories; zero mocking frameworks.
- Boundary stays green: no new imports in Core beyond
  Foundation/Observation (`core_boundary` SwiftLint rule).

**References:** ADR-002, ADR-007, ADR-008.

---

### Task 3 — SwiftData @Model classes and mappers

**Objective:** The persistence representation in `EasySavingData`:
`@Model` reference types plus bidirectional mapping, so domain structs
never learn that SwiftData exists.

**Acceptance criteria:**
- `TransactionModel` and `CategoryModel` `@Model` classes (`Model`
  suffix per convention), living only in `EasySavingData`.
- Bidirectional mappers with unit tests, including id/date/money
  round-trip fidelity.
- `DataPlaceholder` and the `linkProof` wiring in `EasySavingApp`
  deleted (0-2 follow-up, Data half); the app compiles with a plain
  placeholder view until Sprint 2 brings real screens.
- `data_boundary` lint rule stays green.

**References:** ADR-005, ADR-010.

---

### Task 4 — ModelActor repositories with integration tests

**Objective:** Implement the repository protocols as `ModelActor` types
doing off-main persistence work, and prove the sprint's definition of
done: data added through the repository survives a "relaunch".

**Acceptance criteria:**
- Repository implementations as `ModelActor` in `EasySavingData`;
  strict-concurrency clean — no `@unchecked Sendable`, no
  `nonisolated(unsafe)`.
- Integration tests against an in-memory `ModelContainer`: insert →
  fetch → assert, delete → fetch → assert.
- Relaunch proof: data written through one container/context is read
  back through a freshly created one over the same store (simulated
  restart), asserted in a test.
- Package remains fully testable standalone via `swift test` (no Xcode
  required), keeping the package/app test-speed split measured in 0-3.

**References:** ADR-005, ADR-008.

---

## Sprint 2 — Trello tickets

Drafted at Sprint 1 closure. Six cards in dependency order: navigation
and DI infrastructure first, then the DesignSystem the screens consume,
then the two feature screens (list, form) with the category write path
they need in between, and a small closing card that proves the sprint
goal end-to-end ("the app is usable"). Carried-over deferrals get their
home here: composition root and category write path (1-4),
`.sizeThatFits` component snapshots and `.xctestplan` migration (0-4),
and the minimal XCUITest happy path (0-5).

---

### Task 1 — Composition root and coordinator skeleton

**Objective:** Materialize ADR-007 and ADR-004: `AppDependencies` builds
the object graph (shared `ModelContainer` → repositories → use cases)
and an `@Observable` coordinator owns `NavigationPath` via a `Route`
enum, so every later screen plugs into real infrastructure instead of
ad-hoc wiring.

**Acceptance criteria:**
- `AppDependencies.swift` is the only file in the app target importing
  `EasySavingData`; it creates the on-disk `ModelContainer` (schema:
  `TransactionModel`, `CategoryModel`) and injects repositories into use
  cases via initializers.
- `Navigation/` folder: `Route` enum + coordinator owning
  `NavigationPath`; root view driven by the coordinator. No
  `NavigationLink(destination:)` anywhere.
- App boots on simulator into a coordinator-owned placeholder home (the
  real list arrives in 2-3); last placeholder wiring from Sprints 0/1
  removed.
- Coordinator route handling unit-tested where feasible (route push/pop
  as pure state changes).
- Folder layout in the app target proposed with the task and recorded in
  the TASK_LOG entry as precedent.

**References:** ADR-003, ADR-004, ADR-007; 1-4 follow-up (composition
root instantiates the repositories).

---

### Task 2 — DesignSystem foundations

**Objective:** Create the `DesignSystem/` layer that resolves ADR-010's
semantic `String` keys (icon/color) into real SwiftUI values, decide the
theming strategy that ADR-011 left open, and establish the
component-snapshot precedent before feature screens exist.

**Acceptance criteria:**
- `DesignSystem/` folder in the app target: semantic color tokens,
  icon-key and color-key resolution for `Category`, and money formatting
  at the UI edge (minor units + currency code → localized string; no
  `Double` at any point).
- Theming decision (semantic tokens vs asset catalog) documented as a
  new ADR entry.
- First components (e.g. category badge, amount label, transaction row
  shell) built with Dynamic Type support and VoiceOver labels from day
  one.
- Component snapshot suites using `.sizeThatFits` (0-4 follow-up),
  deterministic on second run; `.xctestplan` migration from the same
  follow-up executed or explicitly re-deferred with reasons.

**References:** ADR-010, ADR-011 open decision; 0-4 follow-up.

---

### Task 3 — Transaction list feature

**Objective:** First real screen through the full MVVM-C chain: an
`@Observable` ViewModel in Core exposing state + intent closures, a
SwiftUI view in the app target, navigation decisions owned by the
coordinator.

**Acceptance criteria:**
- `GetCategoriesUseCase` added in Core (rows need category name/icon;
  read-only, existing repository method).
- `TransactionsListViewModel` in Core: talks to use cases only, exposes
  observable state (loading / empty / populated) and intent closures
  (`onAddTapped`, `onTransactionSelected`); zero navigation logic.
- List view: rows built on 2-2 components, empty state, swipe-to-delete
  through `DeleteTransactionUseCase`.
- Coordinator interprets the intents (what "add tapped" means — sheet,
  push — is its decision, recorded as precedent).
- ViewModel unit tests against the existing fakes; snapshot tests for
  empty and populated states.

**References:** ADR-003, ADR-004, ADR-008.

---

### Task 4 — Category write path and default seeding

**Objective:** Close the deliberate 1-4 gap: `CategoryRepository` gains
its write path and the app seeds a default category set, so the 2-5 form
has real categories to pick from.

**Acceptance criteria:**
- `save`/upsert on `CategoryRepository` (Core protocol + SwiftData
  implementation), contract documented on the protocol like the 1-4
  ones; integration tests against the in-memory container.
- Default category set defined in Core with semantic icon/color keys
  (resolved by 2-2's DesignSystem).
- Seeding use case invoked at startup from the composition root;
  idempotent — proven by a run-twice-no-duplicates test.
- Fake repositories updated to implement the documented write contract.

**References:** ADR-005, ADR-010; 1-4 follow-up (category write path).

---

### Task 5 — Transaction form: create and edit

**Objective:** Complete the CRUD flow: a form ViewModel in Core handling
create and edit, presented by the coordinator, with
`AddTransactionUseCase`'s validation errors surfaced to the user instead
of swallowed.

**Acceptance criteria:**
- Form ViewModel in Core: amount, category, date, note; create mode and
  edit mode (pre-populated). Whether edit reuses `AddTransactionUseCase`
  (save is upsert) or introduces `UpdateTransactionUseCase` is decided in
  the task and recorded as precedent.
- Amount entry: decimal text input parsed to `Money` minor units at the
  UI edge — no `Double`, no `Float`; parsing unit-tested (locale
  separators, too many decimals).
- Validation errors (`AddTransactionError`) mapped to user-facing
  messages; error state visible in the UI.
- Coordinator presents the form (add and edit entry points wired from
  the 2-3 intents).
- ViewModel unit tests (happy path, validation failure, edit
  pre-population); snapshot tests for form states.

**References:** ADR-003, ADR-004, ADR-010.

---

### Task 6 — UI happy path and Sprint 2 close

**Objective:** Prove the sprint's definition of done end-to-end and
close the sprint: the template UI tests finally become the minimal
ADR-008 happy path, and the project memory is updated.

**Acceptance criteria:**
- Template XCUITests replaced by one minimal happy path: launch → add
  transaction via the form → it appears in the list (0-5 follow-up).
- Full CRUD verified on simulator (create, edit, delete) — the sprint's
  definition of done.
- Sprint 2 TASK_LOG entries audited; Sprint 3 cards (analytics) drafted
  in Trello and their ticket text of record added to
  `docs/SPRINT_PLAN.md`, per the 0-6 precedent.

**References:** ADR-008; CLAUDE.md workflow; 0-5 follow-up.
