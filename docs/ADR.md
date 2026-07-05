# EasySaving iOS — Architecture Decision Records

This document collects the architecture decisions for the **native iOS
rewrite** of EasySaving. It supersedes the ADR of the original KMP project,
which remains archived as reference (`docs/archive/ADR-kmp.md`).

The project has an explicit dual goal:
1. Portfolio piece demonstrating senior-level native iOS engineering.
2. Training ground for a Senior iOS Engineer interview process whose stack
   emphasizes: modular SwiftUI codebases, MVVM-C, Swift Concurrency,
   REST API integration with offline/retry handling, a three-level testing
   strategy (unit, snapshot, integration) and CI/CD with linters.

Every decision below is therefore evaluated against two criteria: *is it an
industry standard or a current best practice?* and *does it produce
interview-ready talking points?*

---

## ADR-001: Native iOS only — Swift 6 + SwiftUI (supersedes KMP strategy)

**Context:** The original project used Kotlin Multiplatform to share
domain/data/presentation with native UIs. Priorities have changed: the
immediate goal is depth in the modern iOS stack, not breadth across
platforms.

**Decision:** Single native iOS app. Swift 6 language mode with **strict
concurrency checking enabled** from day one. SwiftUI-only UI (no UIKit
screens; UIKit interop only if a specific component demands it, documented
case by case). Minimum deployment target **iOS 17** (required by
`@Observable` and SwiftData; raises the floor for modern APIs while still
being a realistic production target in 2026).

**Alternatives considered:**
- Continue KMP and only polish the iOS half: rejected — the KMP bridge
  work (SKIE, Flow interop) consumes time without adding interview value
  for a pure-iOS role.
- iOS 16 target for wider reach: rejected — it would force
  `ObservableObject`/`@Published` instead of `@Observable`, i.e. practicing
  the old idiom instead of the current one.

**Consequences:** Strict concurrency will surface `Sendable` and actor
isolation errors early and constantly. That friction is intentional: Swift
Concurrency questions are a staple of senior iOS interviews, and debugging
real isolation errors in your own codebase is the best preparation.

---

## ADR-002: Modularization — one local SPM package, two targets (core + infrastructure)

**Context:** The target role explicitly asks for experience "designing
modular iOS architectures". A single app target cannot demonstrate that.
At the same time, this is a three-screen solo project: a heavily sliced
module graph (target-per-feature) would signal over-architecture rather
than judgment. The boundaries kept must each pay for their cost.

**Decision:** One Xcode app target (`EasySaving`) plus a **single local
SPM package** (`EasySavingKit`) containing **two library targets**, cut
along the classic core/infrastructure line:

- **`EasySavingCore`** — domain models, repository protocols, use cases,
  and the `@Observable` ViewModels (presentation logic). Depends on
  nothing in the project. May import `Foundation` and `Observation`;
  **must not import SwiftUI, SwiftData or any networking API** — the
  compiler, not code review, enforces that presentation logic stays
  UI-free and persistence-free.
- **`EasySavingData`** — SwiftData persistence and the networking layer;
  implements the repository protocols declared in `EasySavingCore`.
  Depends on `EasySavingCore`, never the other way around.
- **App target** — SwiftUI views, the `DesignSystem` (a folder of
  reusable, accessibility-first components — Dynamic Type, VoiceOver,
  contrast — deliberately *not* a target until reuse pressure justifies
  it), coordinator/navigation (ADR-004) and the composition root
  (ADR-007). The app is the only place allowed to import everything.

Dependency graph, enforced at compile time:
`App → {EasySavingCore, EasySavingData}`; `EasySavingData → EasySavingCore`.

**Alternatives considered:**
- **Target per feature** (`FeatureTransactionList`, etc.): the pattern
  used by large teams to parallelize ownership and builds. Rejected *for
  now* — at this scale it adds Package.swift ceremony without a felt
  problem behind it. Documented as the natural next slice if features
  multiply; deferring it until it hurts is itself the judgment being
  demonstrated.
- **Single module with folder conventions:** rejected — conventions don't
  compile; module boundaries do. "Core cannot import SwiftData" being a
  build error, not a code-review comment, is precisely the talking point.
- **Multiple Xcode framework targets:** rejected — local SPM packages are
  the current community standard for the same result with less ceremony.

**Consequences:** The two most valuable boundaries (presentation logic
free of UI frameworks; domain free of persistence) are compiler-enforced,
while the module count stays proportionate to the app. Accepted trade-off:
because use cases and ViewModels share a target, the internal rule
"ViewModels talk to use cases, not repositories directly" is convention
(reviewed, not compiled). `internal`-by-default within each target forces
explicit `public` API design at the package surface.

---

## ADR-003: MVVM with @Observable ViewModels

**Context:** State management pattern must be idiomatic modern SwiftUI and
match what the target team uses (they name MVVM-C explicitly).

**Decision:** One `@Observable` ViewModel per screen, held by the View via
`@State`. ViewModels live in `EasySavingCore` (ADR-002), so they import
`Observation` but **cannot** import SwiftUI or SwiftData — the boundary is
compiler-enforced. The ViewModel:
- Exposes read-only observable state (a `ViewState` enum or plain
  properties: `loading / loaded(data) / error(message)`).
- Exposes `async` action methods (`load()`, `save()`, `delete(id:)`)
  invoked from `.task {}` / button actions.
- Is `@MainActor`-isolated; repositories and use cases do the off-main
  work.
- **Never navigates** and never knows the navigation graph — it emits
  intent through delegate closures consumed by the Coordinator (ADR-004).

**Alternatives considered:**
- TCA (The Composable Architecture): powerful and increasingly common, but
  it's a framework-specific idiom; the target team's vocabulary is MVVM-C.
  Learning TCA now would optimize for the wrong interview.
- `ObservableObject` + `@Published` + Combine pipelines: legacy idiom for
  new code on iOS 17+. Combine remains in the codebase only where it is
  still the natural tool (e.g. debouncing search input), which itself is a
  good interview answer: *async/await for asynchrony, Combine for streams
  of values over time, Observation for UI state*.
- Pure SwiftUI (`@State` + `@Environment`, no ViewModels): viable for small
  apps, but it removes the testable presentation seam the interview will
  ask about.

**Consequences:** Presentation logic is unit-testable without UI. The
`@MainActor` + strict concurrency combination forces explicit thinking
about what crosses isolation boundaries — again, deliberate interview
training.

---

## ADR-004: Navigation via Coordinator over NavigationStack (MVVM-C)

**Context:** The target team names MVVM-C. SwiftUI's native primitives
(`NavigationStack`, `NavigationPath`, `.sheet`, `.fullScreenCover`) don't
prescribe who decides *where* to go.

**Decision:** Coordinator pattern adapted to SwiftUI:
- An `@Observable` `AppCoordinator` owns a `NavigationPath` (per tab if a
  `TabView` is introduced) plus presented-sheet state.
- Screens are described by a `Route` enum (`Hashable`), e.g.
  `.transactionForm(mode: .edit(id))`; the coordinator maps routes to
  feature views via `.navigationDestination(for:)`.
- ViewModels signal intent (`onTransactionSelected: (ID) -> Void`); the
  coordinator decides whether that means push, sheet, or nothing.
- Deep-link readiness: because navigation state is a value
  (`NavigationPath` of routes), restoring or constructing a stack from a
  URL is straightforward — worth a demo even if the MVP has no real deep
  links.

**Alternatives considered:**
- Navigation logic inside views (`NavigationLink(destination:)` inline):
  rejected — couples features to each other and makes flows untestable.
- Third-party routers: rejected — native primitives are sufficient and the
  interview value lies in showing you can build the pattern, not import it.

**Consequences:** Screens stay decoupled from each other — a feature's
views never reference another feature's views; only the coordinator knows
the graph. The coordinator is plain logic over value types, so
navigation flows are unit-testable ("selecting a transaction appends
`.transactionForm` to the path").

---

## ADR-005: Persistence with SwiftData behind repository protocols

**Context:** Offline-first local persistence, no backend of record. The
previous project used SQLDelight, valued for explicit SQL. In pure iOS the
realistic candidates are Core Data, GRDB and SwiftData.

**Decision:** **SwiftData**, with two deliberate constraints:
1. `@Model` classes live only in `EasySavingData` and are mapped to plain
   domain structs. Views and ViewModels never touch `@Model` objects.
2. No `@Query` in views. All access goes through repository protocols
   declared in `EasySavingCore` (`TransactionRepository`,
   `CategoryRepository`) and implemented in `EasySavingData` with a
   `ModelActor` for off-main persistence work.

**Alternatives considered:**
- **GRDB:** the closest spiritual successor to SQLDelight (explicit SQL,
  excellent migrations). Strong option; rejected as default because
  SwiftData is the current first-party direction and generates better
  "what's new in the platform" conversation. GRDB remains the documented
  fallback if SwiftData limitations bite (complex aggregation queries for
  analytics are the likely pain point — see Consequences).
- **Core Data:** the incumbent in banking codebases; verbose, and its
  idioms are well covered by knowing SwiftData's (which wraps it).
  Interview questions about Core Data can be answered from theory + the
  SwiftData mental model.

**Consequences:** Skipping `@Query` gives up SwiftData's tightest SwiftUI
integration in exchange for a testable seam and a domain layer that doesn't
know its persistence — the classic Clean Architecture trade-off, now
demonstrable with a first-party stack. Analytics aggregations
(sum-by-category, monthly trends) will be computed in use cases over
fetched data in the MVP; if volume ever demanded pushing aggregation into
the store, that limitation and the GRDB migration path are the documented
answer.

---

## ADR-006: Networking layer with async/await, retries and offline policy

**Context:** The original app was purely local. The target role weights
REST/GraphQL integration and "handling offline, retries, and error states".
A portfolio app with zero networking can't demonstrate that.

**Decision:** Add a thin networking layer inside `EasySavingData` (a
`Networking/` namespace, not a separate target — see ADR-002's rationale
on proportionate slicing), consumed by one real feature: **exchange
rates** for displaying amounts in
a secondary currency (public, keyless API, e.g. Frankfurter). Components:
- `HTTPClient` protocol + `URLSession` implementation, fully async/await.
- Typed endpoint definitions (`Endpoint` value type: path, method, query).
- Error taxonomy distinguishing transport errors, decoding errors and
  HTTP status errors (mapped to a domain `NetworkError`).
- Retry policy with exponential backoff for idempotent GETs.
- Offline behavior: last-fetched rates cached in SwiftData with a
  timestamp; UI degrades gracefully (stale badge) instead of failing.

**Alternatives considered:**
- No networking (keep MVP purely local): rejected — leaves the single most
  weighted skill of the job description undemonstrated.
- Alamofire: rejected — modern `URLSession` + async/await covers the need;
  building the client by hand is the interview-relevant exercise.
- GraphQL client: out of MVP; REST first. GraphQL is prep-by-reading, not
  prep-by-building, at this timeline.

**Consequences:** The exchange-rate feature is deliberately small in
product terms but exercises the full networking checklist from the job
description: async data flows, retries, error states, offline degradation
— each one an ADR-backed story to tell.

---

## ADR-007: Dependency injection via initializer injection + composition root

**Context:** The KMP project used Koin. iOS has no standard DI container,
and senior interviews probe whether you understand DI as a principle rather
than a library.

**Decision:** Protocol-based **initializer injection**, wired in a single
composition root (`AppDependencies`) owned by the app target. Feature
ViewModels receive their use cases/repositories through init. SwiftUI
`Environment` is used only for genuinely ambient, UI-scoped values — not as
a service locator.

**Alternatives considered:**
- Factory / Swinject / swift-dependencies: capable libraries, but a
  container adds indirection without adding interview value; "we didn't
  need a framework for this" is itself a senior answer. swift-dependencies
  is noted as the natural upgrade if test-override ergonomics ever hurt.

**Consequences:** All dependencies are explicit in signatures; tests build
ViewModels with in-memory fakes with zero framework knowledge. The
composition root is the one place allowed to import everything.

---

## ADR-008: Testing strategy — Swift Testing + snapshot + integration

**Context:** The job description names the three levels explicitly: "unit,
snapshot, and integration tests", running in CI.

**Decision:**
1. **Unit tests with Swift Testing** (`@Test`, `#expect`, parameterized
   tests) — the current first-party framework — covering domain use cases,
   ViewModels (with faked repositories) and the networking error/retry
   logic. XCTest remains only where tooling requires it.
2. **Snapshot tests** with `pointfree/swift-snapshot-testing` for
   `DesignSystem` components and key screens, pinned to a fixed device
   configuration and light/dark + Dynamic Type variants.
3. **Integration tests** at the persistence seam: repository
   implementations against an in-memory SwiftData `ModelContainer`
   (insert → query → assert), plus one or two XCUITest happy-path flows
   (add transaction → appears in list) kept deliberately minimal.

**Alternatives considered:**
- ViewInspector for SwiftUI unit-testing views: rejected for MVP — testing
  ViewModels + snapshots covers the same risk with less brittleness.
- Broad XCUITest suites: rejected — slow and flaky; the interview point is
  knowing *why* the pyramid is shaped the way it is.

**Consequences:** Coverage concentrates where logic lives (domain,
presentation, data). Snapshot tests double as living documentation of the
design system.

---

## ADR-009: CI/CD — GitHub Actions + Fastlane + SwiftLint/SwiftFormat

**Context:** The role asks for hands-on CI/CD (GitHub Actions, GitLab CI,
Bitrise, Fastlane) and linters as part of the codebase definition.

**Decision:**
- **GitHub Actions** on `macos` runners. PR pipeline: SwiftLint (strict) +
  SwiftFormat check → build → unit + snapshot tests (simulator, pinned OS
  and device) → integration tests. Concurrency-cancel on new pushes.
- **Fastlane** as the local/CI command layer (`lane :test`, `lane :snap`,
  `lane :build`), so CI scripts and local workflows are the same commands.
- Caching of SPM dependencies and DerivedData keyed on `Package.resolved`.
- TestFlight lane defined but disabled (no distribution need in MVP) —
  present in the repo as evidence of release-pipeline literacy.

**Amendment (Sprint 0, task 0-3):** SwiftLint and SwiftFormat are consumed
as SPM command plugins declared in `EasySavingKit/Package.swift`
(`SimplyDanny/SwiftLintPlugins`, the binary distribution recommended by
SwiftLint, and `nicklockwood/SwiftFormat`). Versions are pinned by
`Package.resolved` like any other dependency, so linting the repo needs no
extra package manager (Homebrew/Mint). Both are build-time tools, never
linked into shipping code; they are recorded here to satisfy the
"ADR entry before any third-party dependency" rule. Fastlane itself is
pinned via `Gemfile.lock`.

**Consequences:** Every PR proves the three test levels run in CI, which is
verbatim what the job description asks to have done before.

---

## ADR-010: Domain modeling conventions (adapted from KMP ADR-007)

**Decision:** Every type in `Domain` follows these conventions unless a
later ADR documents an exception:

1. **Domain models are structs** (value semantics), `Sendable`,
   `Equatable`, `Identifiable` where applicable. Reference semantics live
   only in `@Model` persistence classes (ADR-005).
2. **Identifiers:** typed wrappers (`Transaction.ID = Tagged<UUID>` or a
   nested `struct ID: Hashable`) over **UUID**, generated client-side.
   Rationale change vs KMP: SwiftData has no auto-increment concept;
   UUIDs are the platform norm and keep the door open for sync.
3. **Relationships by id** (`Transaction.categoryID`), never embedded
   objects, in the base model. Enriched read models (transaction + resolved
   category) are built by use cases for presentation.
4. **Amounts:** `Money` struct wrapping an `Int` amount in minor units
   (cents) plus a `Currency` code. Never `Double`. Formatting via
   `Decimal`/`FormatStyle` only at the UI edge.
5. **Dates:** business dates that are day-granular (a transaction's date)
   are Foundation `Date` normalized through `Calendar` at the domain
   boundary, with an explicit `createdAt: Date` for stable ordering. All
   calendar math goes through injected `Calendar`, never manual
   second-arithmetic (DST safety — a classic interview probe).
6. **Icon/color** on `Category` remain semantic `String` keys (SF Symbol
   name, hex color), resolved by `DesignSystem`.

---

## ADR-011: MVP scope

**Context:** Interview in 1–2 weeks; the project must reach "demonstrable"
state fast, then keep growing as ongoing practice.

**Decision:** MVP = transactions CRUD + categories + local analytics
(Swift Charts) + the exchange-rate networking feature (ADR-006), built in
this order:

1. Package skeleton + CI green (walking skeleton).
2. Domain + Data with tests (fastest interview value per hour).
3. Transaction list + form features with coordinator navigation.
4. Analytics with Swift Charts.
5. Networking feature + offline/retry handling.
6. Snapshot suite + polish (Dynamic Type, VoiceOver pass).

Out of MVP (documented roadmap, unchanged): budgets with alerts,
multi-account, multi-currency accounts, remote sync, widgets/App Intents.

**Consequences:** Steps 1–3 alone already cover the majority of likely
interview themes (modularity, MVVM-C, concurrency, testing, CI). Each later
step adds one themed talking point at a time.

---

*Upcoming decisions still to document (to be added once resolved):*
- *Design-system theming strategy (semantic color tokens vs asset catalog).*
- *Whether analytics aggregation moves into the store (GRDB migration
  trigger, see ADR-005).*
- *App Intents / widget extension as post-MVP showcase.*
