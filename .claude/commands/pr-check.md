---
description: Pre-PR verification — format, lint, fastlane lint + test. Run when a ticket is considered done, before creating the PR.
---

Run the pre-PR verification pipeline from the repo root, in this exact
order, stopping at the first failure:

1. `./format.sh`
2. `./lint.sh`
3. `bundle exec fastlane lint`
4. `bundle exec fastlane test`

After `./format.sh`, run `git status --short`: if it rewrote any files,
list them — they must be reviewed and committed before the PR.

When every step passes, summarize the results (tests run, lint status,
files reformatted if any) and tell the user they have **green light** to
create the PR manually.

If any step fails, show the relevant failure output, do NOT continue with
the remaining steps, and state clearly that there is no green light yet.
