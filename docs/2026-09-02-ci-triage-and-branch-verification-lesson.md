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
| coverage | `7d53c0c8` (run `head_branch`: `main`) | current at capture time | Bug already independently fixed by the time `merged` reached its current tip |
| lint | `7d53c0c8` (run `head_branch`: `main`) | current at capture time | Already clean on `merged`'s current tip |
| integration | `7d53c0c8` (run `head_branch`: `main`) | current at capture time | Same root cause as coverage; already fixed |

None of the four represented a currently-broken state on `merged`.

## A real mistake, and how it was caught

The coverage, lint, and integration rows are one Actions run,
[33597403060](https://github.com/diazMelgarejo/periscope/actions/runs/33597403060)
(workflow `CI`, event `push`, created `2026-09-02T06:06:08Z`). The run
record's `head_branch` is `main` and its `head_sha` is `7d53c0c8`.
Read that branch from the run record. Commit reachability is a
separate check, made with `git merge-base --is-ancestor`.

`7d53c0c8` is the tip of `origin/main` (merge of pull request #45,
committer `2026-09-02T06:06:05Z`). A fresh clone defaults to `main`,
and several fixes were built against that commit before the run
record was checked. The commit is absent from `merged` history.
`git merge-base --is-ancestor 7d53c0c8 d64726e9` exits 1. `d64726e9`
is the `merged` tip named later in this doc. The same command against
`origin/merged` at `ea823133` (re-checked 2026-10-03) also exits 1.
Both pairs diverge at `852b8e38`. `git log --oneline
7d53c0c8..d64726e9 | wc -l` still returns **695**: `A..B` counts
commits reachable from B excluding commits reachable from A. That
number is the size of the range against the pinned tip `d64726e9`.
Re-running it against a later `origin/merged` prints a different
count (741 against `ea823133` on 2026-10-03) and still says nothing
about ancestry. `merged` at `d64726e9` had already carried fixes for
the same issues, in a substantially reshaped `internal/db/sessions.go`
(`wc -l`: 1786 lines at `7d53c0c8`, 4215 lines at `d64726e9`).

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

1. **Which branch the failing run targeted.** Read `head_branch` from
   the Actions run
   (`GET /repos/{owner}/{repo}/actions/runs/{run_id}`). Then, as a
   separate check, ask whether that commit is in `merged` history
   with `git merge-base --is-ancestor <sha> origin/merged` (exit 0
   means it is). `git log <sha>..origin/merged` is only a range size;
   pin the `merged` tip you counted. On this incident `head_branch`
   was `main`, and `7d53c0c8` is outside `origin/merged` history.
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
