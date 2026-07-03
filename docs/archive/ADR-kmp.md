# EasySaving — Architecture Decision Records

This document collects the architecture decisions made during the design
phase of the project, with their context and the trade-offs considered.
It will be updated as the project evolves.

---

## ADR-001: Kotlin Multiplatform as the code-sharing strategy

**Context:** The project has a dual goal: to serve as a portfolio piece and
as a vehicle for learning KMP, modern Jetpack Compose and modern SwiftUI,
while maintaining genuine native mastery of both platforms.

**Decision:** Share domain, data and presentation (ViewModels) via KMP.
Keep the UI layer 100% native (Jetpack Compose on Android, SwiftUI on iOS).

**Alternatives considered:**
- Compose Multiplatform (also sharing UI): rejected because it would dilute
  the demonstration of native SwiftUI mastery, which is one of the project's
  explicit goals.
- Fully independent native apps (no KMP): rejected because it wouldn't meet
  the goal of practicing business logic sharing.

**Consequences:** Higher build complexity (two toolchains, iOS/Android
targets in Gradle) in exchange for a more complete demonstration of
architectural judgment: what gets shared, what doesn't, and why.

---

## ADR-002: SQLDelight as the local persistence layer

**Context:** We need a local, offline-first database, accessible from
shared Kotlin and available on both platforms.

**Decision:** SQLDelight.

**Alternatives considered:**
- **Room (KMP):** already supports multiplatform, but with less production
  multiplatform track record than SQLDelight today. Also, SQLDelight
  generates type-safe APIs from explicit SQL, which demonstrates real SQL
  handling (useful for interviews) instead of fully abstracting it away.

**Consequences:** Schema migrations are managed manually and versioned via
SQLDelight's `.sqm` files — this will be documented as a portfolio strength
(real migration management, not just a "hardcoded v1 model").

---

## ADR-003: Shared ViewModels in KMP (not just domain/data)

**Context:** The ViewModel is, by definition, agnostic of how the UI is
rendered: it decides *what* should be presented, not *how*. This makes it,
in principle, suitable for multiplatform sharing, beyond domain and data.

**Decision:** Share ViewModels using `androidx.lifecycle.ViewModel`
(multiplatform), exposing observable state (`StateFlow`) and action
functions (intents). Navigation is explicitly excluded from this layer
(see ADR-004).

**Problems identified and the solution adopted:**

1. **`StateFlow` → Swift interop.** `Flow` isn't idiomatic in Swift. We use
   the **SKIE** plugin (Touchlab) to automatically generate `async/await`
   equivalents and Swift-friendly types from the coroutines/Flow exposed by
   the shared ViewModel.

2. **Lifecycle on iOS.** `ViewModelStoreOwner` doesn't exist natively on
   iOS. Each shared ViewModel's lifecycle is explicitly tied to the
   lifecycle of the SwiftUI `View` (created/released in
   `onAppear`/`onDisappear` or an equivalent container), avoiding memory
   leaks from ViewModels that never get released.

3. **Bridge to `@Observable` (modern SwiftUI, iOS 17+).** A Swift
   `@Observable` class is implemented that subscribes to the shared
   `StateFlow` (via SKIE) and republishes changes as native observable
   properties, letting SwiftUI Views use Swift's idiomatic reactivity
   pattern instead of observing a `Flow` directly.

**Alternatives considered:**
- Native per-platform ViewModel, consuming only the shared use cases:
  simpler and "safer", but duplicates presentation logic (state mapping,
  loading/error handling) on both platforms.

**Consequences:** Higher upfront investment in the interop bridge
(Sprint 1), in exchange for eliminating presentation-logic duplication
across platforms and demonstrating how to solve the real problems of
sharing reactive state between different UI paradigms.

---

## ADR-004: 100% native navigation, out of KMP's scope

**Context:** Navigation is heavily dependent on the UI framework
(`NavHost`/`NavController` in Compose vs `NavigationStack`/`NavigationPath`
in SwiftUI), and there's no mature common abstraction that doesn't end up
forcing one platform's paradigm onto the other.

**Decision:** The shared ViewModel never navigates and never knows about
the navigation graph. It only exposes action functions (e.g.
`onTransactionSelected`) that notify an intent; each platform natively
decides whether that translates into navigation and how.

**Consequences:** The UI surface (including navigation) is kept as a
demonstration of idiomatic native mastery on each platform. If avoiding
duplicate re-navigation on recomposition becomes necessary in the future,
adding a one-shot event channel (`SharedFlow`) will be evaluated — pending,
not implemented in the MVP.

---

## ADR-005: Koin as the dependency injection framework

**Context:** We need working DI in shared Kotlin, consumable from both
Android and iOS.

**Decision:** Koin.

**Alternatives considered:**
- Hilt: no multiplatform support (limited to Android/JVM), rejected due to
  a direct incompatibility with the goal of sharing domain/data/presentation.

**Consequences:** Shared Koin module configuration, with platform-specific
entry points to initialize the dependency graph from `Application`
(Android) and from the app's startup point (iOS).

---

## ADR-006: MVP scope — excluding budgets and remote sync

**Context:** The project is developed alongside an active job search, with
availability of ~20-25h/week.

**Decision:** The MVP is limited to CRUD for transactions, categories and
local analytics (offline-first). Budgets with alerts, multi-account,
multi-currency and remote sync are out of the MVP, documented as future
roadmap.

**Consequences:** Lets the project reach a "presentable" state within a
bounded timeframe (~6 weeks) without compromising the depth of the
architectural demonstration at the project's core (KMP, Clean Architecture,
testing, CI/CD).

---

## ADR-007: Domain entity modeling conventions

**Context:** While implementing the first domain models (`Transaction`,
`Category`, `Money`, task 1), several modeling decisions came up that
weren't covered by earlier ADRs. Since these decisions will shape the
structure of every future domain entity (for example, if `Budget` were
added later), they're documented here as an explicit convention rather
than left implicit in the code.

**Decision:** Every entity in `shared/domain` follows these conventions
unless a later ADR documents a justified exception:

1. **Identifiers:** auto-increment `Long` (via `INTEGER PRIMARY KEY
   AUTOINCREMENT` in SQLDelight), not UUID. The problem UUID solves
   (ID collisions between syncing devices) doesn't exist in the MVP, which
   is offline-first and single-device (see ADR-006).
2. **Relationships between entities:** referenced by id (e.g.
   `Transaction.categoryId: Long`), never by embedding the full object
   (`Transaction.category: Category`). Domain mirrors the normalization of
   a relational schema. "Enriched" views (entity + resolved relationship,
   meant for UI) are the responsibility of `presentation`/`data`, not the
   base domain entity.
3. **Dates:** the `kotlinx-datetime` library exclusively (never
   `java.util.Date` or `Foundation.Date`, which would break domain's
   purity from ADR-001). `LocalDate` for business dates (e.g. an expense's
   date). If stable ordering between same-date entities is ever needed,
   add a separate field (`createdAt: Instant`) instead of mixing
   granularities in the same field.
4. **Amounts:** a `value class` backed by `Long` in the currency's smallest
   unit (cents), never `Double`, to avoid floating-point rounding errors in
   financial calculations.
5. **Icon and color:** represented as `String` (a semantic key for icon, hex
   for color), never as platform types (`Bitmap`, `UIColor`, Compose
   `Color`). Each platform decides how to natively render that key, in
   line with ADR-004's principle that each platform resolves the "how" of
   the UI.

**Alternatives considered:**
- UUID for IDs: rejected per point 1 — will be revisited if remote sync is
  added to the roadmap.
- Embedding related objects directly instead of referencing by ID: rejected
  per point 2 — keeps the base model simple and avoids inconsistencies
  between the embedded object and what's actually persisted.
- `Double` for amounts: rejected per point 4 — well-known precision errors
  of binary floating point.

**Consequences:** Any new domain entity must be evaluated against these
five conventions before being implemented. If a future task needs to
deviate (for example, multi-currency would require revisiting point 4),
the deviation must be documented as an update to this ADR, not as a silent
exception in the code.

---

*Upcoming decisions still to document (to be added once resolved):*
- *One-shot event strategy for navigation (if adopted).*
- *SwiftUI UI testing strategy (XCTest vs snapshot testing).*
