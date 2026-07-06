#!/bin/bash
# Rewrites sources with SwiftFormat. Formatting is a local, explicit
# developer action — CI only checks, never rewrites (task 0-3 decision),
# which is why this has no fastlane lane equivalent.
#
# Write mode needs BOTH sandbox grants (verified empirically, task 0-5):
# --allow-writing-to-package-directory satisfies the permission the plugin
# manifest itself declares, and --allow-writing-to-directory . additionally
# covers the app-target sources outside EasySavingKit/. Neither flag alone
# is enough.
set -euo pipefail
cd "$(dirname "$0")"

swift package --package-path EasySavingKit plugin \
  --allow-writing-to-package-directory --allow-writing-to-directory . \
  swiftformat --config .swiftformat --cache ignore \
  EasySaving EasySavingTests EasySavingUITests EasySavingKit/Sources EasySavingKit/Tests
