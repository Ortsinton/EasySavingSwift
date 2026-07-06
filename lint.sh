#!/bin/bash
# Check-only quality gate: SwiftFormat (lint mode) + SwiftLint (strict).
# Runs the exact same commands as the `lint` fastlane lane / CI lint job,
# without the fastlane startup cost. If the lane changes, update this
# script in the same commit (fastlane/Fastfile is the canonical source).
#
# SwiftLint paths look inconsistent with SwiftFormat's on purpose: each
# plugin runs its binary from a different working directory (SwiftLint
# from the package dir, SwiftFormat from the invocation dir — empirical
# finding, task 0-3).
set -euo pipefail
cd "$(dirname "$0")"

swift package --package-path EasySavingKit plugin --allow-writing-to-package-directory \
  swiftformat --lint --config .swiftformat --cache ignore \
  EasySaving EasySavingTests EasySavingUITests EasySavingKit/Sources EasySavingKit/Tests

swift package --package-path EasySavingKit plugin --allow-writing-to-package-directory \
  swiftlint lint --strict --config ../.swiftlint.yml \
  ../EasySaving ../EasySavingTests ../EasySavingUITests Sources Tests
