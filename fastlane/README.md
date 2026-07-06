fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios lint

```sh
[bundle exec] fastlane ios lint
```

SwiftFormat (check mode) + SwiftLint (strict). Same command locally and in CI.

### ios test

```sh
[bundle exec] fastlane ios test
```

Build and run all tests: EasySavingKit via swift test, then the app scheme

### ios snap

```sh
[bundle exec] fastlane ios snap
```

Snapshot tests only, on the pinned simulator (docs/TESTING.md)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
