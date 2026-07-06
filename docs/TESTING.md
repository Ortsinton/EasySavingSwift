# EasySaving iOS — Testing Notes

Operational guide for the test suite. The testing *strategy* (what we test
and why, at which level) lives in ADR-008; this document covers the parts
that need exact, reproducible steps — today that means the snapshot suite
(introduced in task 0-4).

---

## Snapshot tests

Snapshot tests compare a freshly rendered image of a view against a
reference PNG committed to the repo, pixel by pixel. The reference is a
*human-approved* artifact: it is only as trustworthy as the review it got
when it was recorded, and only as stable as the environment it was
rendered in. Everything below exists to keep that environment fixed.

### Pinned environment

Record and verify snapshots **only** under this configuration:

| What | Pinned value |
| --- | --- |
| Simulator device | iPhone 17 (the `device:` in every Fastlane lane) |
| Simulator OS | iOS 26.5 (build 23F77) |
| Xcode | 26.6 (17F113) — pinned in CI via `DEVELOPER_DIR` |
| Appearance | Light, forced per test via `traits:` |
| Layout | Explicit per test — see layout policy below |
| View inputs | Fixed literals/fixtures, never live data, dates or locale-dependent values |

A reference recorded under a different simulator OS or Xcode version is
invalid even if tests happen to pass locally: it will drift from CI.
When the pinned environment changes (e.g. a simulator runtime update),
re-record the whole suite deliberately, in its own commit.

### Layout policy

- **Screens:** `.image(layout: .fixed(width: 390, height: 844), ...)` —
  explicit canvas in points (iPhone 13 dimensions). The canvas size is
  part of the test contract; never let a screen "measure itself".
- **Components (DesignSystem, Sprint 2+):** `.sizeThatFits` — the image
  hugs the component's intrinsic size.
- **Never `.device(config:)`.** Found in task 0-4: device layouts are
  runner-sensitive. The same test on the same simulator and runtime
  produced images vertically shifted by 3.3 pt depending on whether it
  ran from Xcode or from `xcodebuild` (fastlane) — the simulated
  safe-area insets are applied through a `UIWindow.safeAreaInsets`
  override that UIKit does not honor identically in both process
  environments. Known issue family upstream:
  [#810](https://github.com/pointfreeco/swift-snapshot-testing/issues/810),
  [#180](https://github.com/pointfreeco/swift-snapshot-testing/issues/180),
  [#430](https://github.com/pointfreeco/swift-snapshot-testing/issues/430),
  [discussion #558](https://github.com/pointfreeco/swift-snapshot-testing/discussions/558).
  Full investigation: TASK_LOG task 0-4.

### Precision policy

Default (exact) precision, always. `precision`/`perceptualPrecision`
tolerances hide exactly the small-area regressions snapshots exist to
catch; the 0-4 investigation confirmed that our only observed
nondeterminism was geometric (a variable to eliminate), not antialiasing
noise (a difference to tolerate). Adding a tolerance requires a
documented reason in the PR that introduces it.

### Verifying (the default mode)

```sh
bundle exec fastlane snap    # snapshot suite only, pinned simulator
```

Running the suite from Xcode (⌘U on the pinned simulator) is equally
valid — references are runner-independent *by construction* thanks to
the layout policy. `fastlane snap` is canonical because it is the exact
command CI runs.

A snapshot failure attaches the reference and the actual image (paths in
the failure message); look at both before assuming either is wrong.

### Recording (deliberate, reviewed)

The default record mode is `.missing`: an existing reference is never
overwritten silently, and a missing one is written to disk **and the
test fails on purpose** — forcing a human to look at the image before
blessing it.

- **New test:** just run it. First run fails and writes the reference;
  inspect the PNG by eye; run again — it must pass with no diff (that
  second green run is the determinism check, always do it).
- **Intentional UI change:** delete the affected PNGs and follow the
  new-test flow, or re-record a whole suite with
  `@Suite(.snapshots(record: .all))` — then **remove the trait before
  committing**; a committed `.all` turns the suite into a test that can
  never fail.
- Review re-recorded references in the PR diff like code: every changed
  PNG is either the change you intended or a regression you just
  approved.

### References on disk

- References live in `__Snapshots__/` next to the test file, named
  `<TestSuiteFileName>/<test-name>.<assert-index>.png`, and are
  committed to the repo.
- Both path components are **derived from source**: renaming a test
  file, suite or function (by hand *or by a formatter — SwiftFormat's
  `swiftTestingTestCaseNames` rewrites `@Test` function names*)
  orphans the old reference and records a new one. After any rename:
  delete the orphaned PNGs and re-run the record flow. Orphaned
  references in the repo are lies — remove them on sight.
