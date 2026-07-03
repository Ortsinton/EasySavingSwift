# EasySaving — Module Structure (Skeleton)

Proposed Gradle module and folder structure for the project. This document
defines **what exists and its responsibility**, not its implementation. It
serves as a guide for Sprint 0.

```
EasySaving/
│
├── shared/                              # All shared Kotlin code (KMP)
│   ├── build.gradle.kts                 # Targets: android, iosArm64, iosSimulatorArm64
│   │
│   ├── domain/                          # Module :shared:domain
│   │   ├── model/                       # Transaction, Category, Money, etc.
│   │   ├── repository/                  # Interfaces (TransactionRepository, CategoryRepository)
│   │   └── usecase/                     # AddTransactionUseCase, GetMonthlyAnalyticsUseCase...
│   │       # No dependencies on Android/iOS or infrastructure frameworks.
│   │       # 100% testable with plain kotlin.test.
│   │
│   ├── data/                            # Module :shared:data
│   │   ├── local/
│   │   │   ├── sqldelight/              # .sq files (schema + queries)
│   │   │   └── EasySavingDatabase.kt    # Wrapper around the generated DB access
│   │   ├── mapper/                      # Entity (SQLDelight) <-> Domain model
│   │   └── repository/                  # Implementations of the domain interfaces
│   │
│   ├── presentation/                    # Module :shared:presentation
│   │   ├── transactionlist/
│   │   │   ├── TransactionListViewModel.kt
│   │   │   └── TransactionListUiState.kt
│   │   ├── transactionform/
│   │   │   ├── TransactionFormViewModel.kt
│   │   │   └── TransactionFormUiState.kt
│   │   └── analytics/
│   │       ├── AnalyticsViewModel.kt
│   │       └── AnalyticsUiState.kt
│   │       # Each ViewModel exposes StateFlow<UiState> + action functions.
│   │       # Zero references to navigation (see ADR-004).
│   │
│   └── di/                              # Shared Koin modules
│       └── SharedModule.kt
│
├── androidApp/                          # Module :androidApp
│   ├── build.gradle.kts
│   └── src/main/kotlin/.../
│       ├── EasySavingApplication.kt     # Koin startup entry point on Android
│       ├── navigation/                  # NavHost + NavGraph (Compose Navigation)
│       └── ui/
│           ├── transactionlist/         # Composables consuming TransactionListViewModel
│           ├── transactionform/
│           └── analytics/               # Composables + charts (Vico or another lib)
│
├── iosApp/                              # Xcode project
│   ├── iosApp.xcodeproj
│   └── iosApp/
│       ├── EasySavingApp.swift          # Koin startup entry point on iOS
│       ├── Navigation/                  # NavigationStack + NavigationPath
│       ├── Bridges/                     # @Observable <-> StateFlow bridges (see ADR-003)
│       │   ├── ObservableTransactionListViewModel.swift
│       │   ├── ObservableTransactionFormViewModel.swift
│       │   └── ObservableAnalyticsViewModel.swift
│       └── Views/
│           ├── TransactionList/
│           ├── TransactionForm/
│           └── Analytics/               # Views + Swift Charts
│
├── .github/
│   └── workflows/
│       └── ci.yml                       # Matrix: test :shared (JVM+iOS simulator),
│                                         # build androidApp, build iosApp
│
├── docs/
│   ├── ADR.md                           # This decision-record document
│   ├── TASK_LOG.md                      # Log of completed tasks and follow-up
│   └── screenshots/                     # Captures/gifs for the README
│
├── settings.gradle.kts                  # include(":shared", ":shared:domain",
│                                         #         ":shared:data", ":shared:presentation",
│                                         #         ":androidApp")
└── README.md
```

## Notes on module dependencies

```
:shared:domain        <-- depends on nothing else in the project
:shared:data          <-- depends on :shared:domain
:shared:presentation  <-- depends on :shared:domain (uses the use cases)
                          does NOT depend on :shared:data directly (goes through domain)
:shared:di            <-- wires data + domain + presentation (Koin graph)
:androidApp           <-- depends on :shared:presentation, :shared:di
iosApp (via framework)<-- consumes the compiled :shared binary (all layers)
```

This separation forces `presentation` to never know persistence details
(SQLDelight), and keeps `domain` pure — it's the boundary you can point to
directly in an interview to talk about Clean Architecture with a real
example, not just a theoretical one.

## Package naming conventions

```
com.ortsinton.easysaving.domain.model
com.ortsinton.easysaving.domain.usecase
com.ortsinton.easysaving.data.local
com.ortsinton.easysaving.data.repository
com.ortsinton.easysaving.presentation.transactionlist
com.ortsinton.easysaving.di
```

## Next technical step (Sprint 0)

1. Create the KMP project (via the official KMP template or the
   `kmp-nativecoroutines` template) with the `android`, `iosArm64`,
   `iosSimulatorArm64` targets.
2. Set up SQLDelight in `:shared:data` with a minimal schema (a single
   `Transaction` table) and verify it generates code for both targets.
3. Set up Koin with an empty module injectable from `androidApp` and from
   `iosApp`.
4. Set up GitHub Actions with a job that builds `:shared` for both targets
   and runs a green dummy test.
5. Confirm the SKIE pipeline is integrated and generates Swift interop from
   a test `Flow` before writing the first real ViewModel (Sprint 1).
