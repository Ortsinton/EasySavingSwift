# EasySaving — Task Log

This document complements the git history: while `git log` tells you *what*
changed, this log captures the *why* behind decisions made in each task, the
problems encountered during implementation, and any follow-up/debt left
pending. Every new Claude Code session should read the most recent entry
before starting the next task on the Trello board.

One entry is added per completed task, in chronological order.

---

## Task 1: Define domain models

**Branch/PR:** `1-models` → merged into `main` in PR #1
**Commits:** `312e78a` (implementation), `367da67` (syntax fix)
**References:** ADR-001, ADR-006, ADR-007 (new, see below)

### Summary

Created the three domain data classes requested (`Transaction`, `Category`,
`Money`) in `shared/src/commonMain/kotlin/com/ortsinton/easysaving/domain/model/`,
with no dependency on Android, iOS or SQLDelight. Added `kotlinx-datetime` as
a multiplatform dependency to represent dates.

### Decisions made (with future implications — see ADR-007)

- **`Long` auto-increment IDs, not UUID.** There's no remote sync in the MVP
  (ADR-006), so the problem UUID solves (collisions between devices) doesn't
  apply yet. Revisit if remote sync is added.
- **`Transaction` references `categoryId: Long`, doesn't embed `Category`.**
  Domain models relationships the way a relational schema would (foreign
  key), avoiding duplicating category data on every transaction. "Enriched"
  views (transaction + resolved category) are the responsibility of
  `presentation`/`data`, not this base model.
- **Dates via `kotlinx-datetime`, not `java.util.Date` or `Foundation.Date`.**
  `Transaction.date` is `LocalDate` (just the expense's date, no time). If
  stable ordering between same-day transactions is ever needed, add a
  separate field (`createdAt: Instant`) instead of mixing it into `date`.
- **`Money` is a `value class` backed by `Long` in cents, not `Double`.**
  Avoids floating-point rounding errors in amounts.
- **`icon` and `color` in `Category` are `String`**, not platform types
  (`Bitmap`, `UIColor`, Compose `Color`). `icon` is a semantic key (e.g.
  `"restaurant"`) and `color` a hex value (`"#FF6B35"`); each platform
  decides how to render it natively.

### Problems encountered during implementation

- Files were initially created under `shared/src/commonMain/domain/`
  (missing the `kotlin/` segment), so Android Studio didn't recognize them
  as Kotlin source and syntax highlighting didn't work. Fix: all Kotlin code
  in a KMP source set must live under `.../<sourceSet>/kotlin/...`.
- Adding `kotlinx-datetime` to the version catalog (`libs.versions.toml`)
  hit two chained errors: (1) the alias was named `androidx-datetime`
  instead of `kotlinx-datetime` (the typesafe accessor is generated from the
  alias key, not from the artifact name), and (2) a typo in the module
  coordinate (`korlinx-datetime` instead of `kotlinx-datetime`). Gradle sync
  didn't fail because the catalog itself was valid — the failure only
  showed up when actually resolving the dependency, and it did so across
  all 7 compilation targets at once (androidMain, androidHostTest,
  iosArm64Main/Test, iosSimulatorArm64Main/Test), which is the expected
  behavior: a `commonMain` dependency propagates to every target
  automatically, there's no need to declare it per target.
- `kotlinx-datetime` version: confirmed `0.8.0` as the latest stable release
  (May 2026) by checking the official repo, instead of assuming the `0.7.1`
  already sitting in cache as a transitive dependency.

### Follow-up generated (not resolved in this task)

- Pending in Trello: **"Clean up Compose Multiplatform scaffolding in
  `:shared`"** — remove `App.kt`, `Greeting.kt`, `GreetingUtil.kt`,
  `Platform.kt` and the Compose dependencies in `commonMain.dependencies`
  of `shared/build.gradle.kts`, since they contradict ADR-001 (100% native
  UI). This task hasn't been executed yet.

### Final state

Code review (`/code-review` skill, medium level) → **Approved**, no
blocking findings.

---

## Task 2: Configure SQLDelight schema for the Transaction table

**Branch/PR:** `task-2-sqldelight-transaction`
**Commits:** `21cbe75` (SQLDelight dependency + Transaction schema)
**References:** ADR-002, ADR-007

### Summary

Set up SQLDelight in `:shared` and defined the initial schema to persist
transactions. Added the plugin and the `runtime` library (version `2.3.2`) to
the version catalog, wired the plugin into the root and `:shared` build scripts,
configured the `EasySavingDatabase` database
(`packageName = com.ortsinton.easysaving.data.local.sqldelight`), and created
`TransactionEntity.sq` with the `CREATE TABLE` plus the basic queries
(`insert`, `selectAll`, `selectById`, `update`, `deleteById`).

### Decisions made

- **Table named `TransactionEntity`, not `Transaction`.** Two reasons:
  `TRANSACTION` is a reserved SQL keyword (`BEGIN TRANSACTION`), and it avoids a
  name clash with the `domain.model.Transaction` class when both are imported in
  the data-layer mappers.
- **Columns follow ADR-007.** `Long` autoincrement `id`; amount stored as
  `amountCents INTEGER` (matching the `Money` value class); `date` as an
  ISO-8601 `TEXT` (`LocalDate`); category referenced by `categoryId`, never
  embedded.
- **`verifyMigrations = true` enabled from the start.** It is a no-op today
  (schema v1 has no `.sqm` migration files yet), but wires in real, versioned
  migration verification as required by ADR-002: once `.sqm` files exist
  (schema v2+), Gradle checks that applying them reproduces the schema defined
  by the `.sq` files, so drift can't ship unnoticed.
- **Scope limited to `Transaction`.** The ticket asked specifically for
  `Transaction.sq`; the `Category` table is deferred to its own ticket.

### Problems / clarifications during implementation

- **`INTEGER` vs overflow.** Concern was raised that storing the amount as
  `INTEGER` could overflow the domain's `Long`. It cannot: SQLite has no
  fixed-width integer types — its `INTEGER` storage class holds up to 8 bytes
  (signed 64-bit), exactly the range of a Kotlin `Long`, and SQLDelight maps it
  to `Long` (confirmed in the generated `amountCents: Long`). `NUMBER` was
  rejected: it would get `NUMERIC` affinity and map to `Double`, precisely what
  ADR-007 forbids for money.
- **No local JDK on PATH.** `java`/`gradle` weren't available directly; builds
  were run using the JBR bundled with Android Studio
  (`/Applications/Android Studio.app/Contents/jbr/Contents/Home`) as
  `JAVA_HOME`.

### Verification

- `TransactionEntity.sq` generates `TransactionEntity`,
  `TransactionEntityQueries` and `EasySavingDatabase`; generated `amountCents`
  is `Long` and `Schema.version = 1` (schema v1).
- Compiles for all targets: Android AAR (`:shared:assemble`) and both iOS
  frameworks (`compileKotlinIosArm64`, `compileKotlinIosSimulatorArm64`).

### Follow-up generated (not resolved in this task)

- **Runtime wiring (next ticket).** Only `sqldelight:runtime` was added, which
  is enough to generate code and compile but does **not** create the database or
  run `CREATE TABLE` at runtime. Still pending: platform drivers
  (`android-driver` in `androidMain`, `native-driver` in `iosMain`), an
  `expect/actual DriverFactory` (Android needs a `Context`, iOS doesn't), the
  `EasySavingDatabase.kt` wrapper, and Koin wiring. The driver constructor is
  what invokes `Schema.create()`.
- Still pending from Task 1: **"Clean up Compose Multiplatform scaffolding in
  `:shared`"** (remove `App.kt`, `Greeting.kt`, `GreetingUtil.kt`, `Platform.kt`
  and the Compose dependencies), which contradicts ADR-001.
