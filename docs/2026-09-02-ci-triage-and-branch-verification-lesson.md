---
title: CI triage on merged — a branch-verification mistake worth keeping
description: How four reported CI failures on periscope turned out to be stale, and the branch-verification discipline that would have caught it sooner
---

# CI triage on `merged`: investigation log and a mistake worth keeping

**Context.** Four CI job links were reported as failing (a Benchmark
Gate run and a coverage/lint/integration set), plus a request to check
all CI and fix anything real. This doc records what was actually
found, including a real process mistake made along the way and how it
was caught -- worth keeping precisely because the mistake, not just
the fix, is the reusable lesson for next time.

## What the four reported jobs actually were

| Job | Commit tested | Age | Status on `merged` today |
| --- | --- | --- | --- |
| Benchmark Gate | `a158f3f9` | 2026-07-30 (a month old) | The failing file (`internal/pricing/supplemental.go`) no longer exists in this form |
| coverage | `7d53c0c8` (on `main`) | current at capture time | Bug already independently fixed by the time `merged` reached its current tip |
| lint | `7d53c0c8` (on `main`) | current at capture time | Already clean on `merged`'s current tip |
| integration | `7d53c0c8` (on `main`) | current at capture time | Same root cause as coverage; already fixed |

None of the four represented a currently-broken state on `merged`.

## A real mistake, and how it was caught

`7d53c0c8` is a commit on `main`, not `merged` -- confirmed only after
first cloning the repo (which defaults to `main`) and building several
fixes against it without checking. `git merge-base --is-ancestor
7d53c0c8 origin/merged` later confirmed `main` was **695 commits
behind** `merged` at the time. The two branches hadn't diverged
(`7d53c0c8` genuinely is an ancestor of `merged`), but `merged` had
moved forward independently and already carried fixes for the same
issues, in a substantially reshaped `internal/db/sessions.go` (1787
lines on the stale snapshot vs. 4216 lines on the real `merged` tip).

Re-verified against the actual, current `merged` tip once this was
caught:

- `internal/db/sessions.go`: `FindPruneCandidates` and
  `ListSessionsModifiedBetween`'s `Scan()` calls both correctly match
  their SQL column lists (61=61, 71=71 -- counted with a
  parenthesis-aware parser after a naive comma-split first produced a
  false positive on a `COALESCE(a, b) AS c` expression, which is worth
  remembering too: don't `.split(",")` a raw SQL column list without
  respecting parens).
- `golangci-lint run` (exact CI version, v2.10.1): **0 issues** on the
  current `merged` tip.
- The real, current CI check for `merged`'s actual tip (`d64726e9` at
  time of writing) shows exactly one check (`build-and-push`),
  `success`. The coverage/lint/integration jobs apparently only run on
  pull requests, not on direct pushes to `merged` -- so "CI is green"
  for `merged` itself is a narrower claim than "every job type has
  recently run and passed."

## The reusable lesson

Before touching any code in response to a reported CI failure here,
confirm three things explicitly, not just "does the file exist":

1. **Which branch does the failing job's commit actually belong to** --
   `main` and `merged` are related but not interchangeable, and a
   commit being *an ancestor* of `merged` does not mean `merged` is
   still in that state.
2. **How old is the run** -- a job link from weeks or months ago may be
   testing code that's since been substantially reshaped or already
   fixed by unrelated work.
3. **What the real, current tip's own CI status says**, checked
   directly (`GET /repos/{owner}/{repo}/commits/{sha}/check-runs`) --
   this is more authoritative than re-deriving pass/fail from a local
   clone, especially when the local clone's default checkout doesn't
   match the branch actually in question.

Applying all three here turned what looked like four real bugs needing
fixes into a correct, verified "already resolved, nothing to do" --
after several fixes had already been built (and then discarded) against
the wrong branch. That work wasn't wasted diagnostically (the DB
column-count mismatch pattern and the `golangci-lint` findings were
real, just already fixed elsewhere), but it should have been caught at
step 1, before any code was written.

This applies directly to future upstream `AgentsView` syncs and any
periscope-side remediation work: confirm the target branch and its
real current tip before diagnosing, not after.
