# PR 80 ECC review follow-up plan

- **Status:** Plan. Not implemented.
- **Date:** 2026-10-03
- **PR:** <https://github.com/diazMelgarejo/periscope/pull/80>
- **Branch:** `cursor/pr49-snapshot-077b` (base `merged`)
- **Audited head:** `61a18c329f2ce49a5b1259a944179999488608ae`

## Constraint

Follow-up work stays on `cursor/pr49-snapshot-077b`. Pull request #49 and
`experiment/upstream-merge-measurement-20260902` stay unchanged. This document
records how to answer the ECC Tools comments. It does not change Go, workflows,
or tests.

## What ECC reviewed

ECC Tools posted issue comments only. There are no ECC review threads on lines.
`ecc-tools[bot]` left 18 comments: the same six audits, three times, on three
commits.

| Commit                                     | When the text applies                   |
| ------------------------------------------ | --------------------------------------- |
| `6491d41e865c07157a40e5c868cfbfecf73d5119` | First pass, before the requested anchor |
| `966bbd612e4a289fb1a30f80e72652898957ea78` | Anchor comment and its five siblings    |
| `61a18c329f2ce49a5b1259a944179999488608ae` | Follow-up pass on the current head      |

Commits after `6491d41e` edit only
`docs/2026-09-02-ci-triage-and-branch-verification-lesson.md` and
`docs/2026-09-02-upstream-merge-effort-assessment.md`. The pull request still
touches five paths versus `merged`, and every audit still says it scanned those
five files. The claims do not change between rounds.

The five paths are `.github/workflows/bench-pr.yml`, the two docs above,
`internal/sync/watch_backend_fsnotify.go`, and
`internal/sync/watch_backend_fsnotify_test.go`.

Every comment ends with the same publication note: check publication was denied
or unavailable until an app owner enables Checks read and write and the
installation owner approves that permission. That note is inventoried once,
under theme "Checks publication", instead of being copied onto every row.

## Comment inventory

| Comment                                                                                  | Audit                      | Claim                                                                                                                                                                                                   |
| ---------------------------------------------------------------------------------------- | -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [5965418993](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965418993) | Security Evidence          | Gate passed on `6491d41e`. No scanner-evidence gap. Mode enforce.                                                                                                                                       |
| [5965419143](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965419143) | PR Risk Taxonomy           | Neutral. Buckets: Security Evidence (`bench-pr.yml`); CI/CD Recommendation (coverage lag, missing failure-mode evidence, dependency or CI drift). Paths also include the fsnotify backend and its test. |
| [5965419271](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965419271) | Reference Set Readiness    | Neutral. 0/7 areas have reference evidence.                                                                                                                                                             |
| [5965419445](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965419445) | Hosted Promotion Readiness | Passed. 0 evaluator scenarios matched.                                                                                                                                                                  |
| [5965419633](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965419633) | PR Config Audit            | Passed. No issues in `.github/workflows/bench-pr.yml`.                                                                                                                                                  |
| [5965419789](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965419789) | PR Harness Audit           | Passed. No harness issues in that workflow.                                                                                                                                                             |
| [5965563700](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965563700) | Security Evidence          | Same pass, on `966bbd61`. Anchor comment.                                                                                                                                                               |
| [5965563823](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965563823) | PR Risk Taxonomy           | Same two buckets and the same three paths, on `966bbd61`.                                                                                                                                               |
| [5965563968](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965563968) | Reference Set Readiness    | Same 0/7 gap list, on `966bbd61`.                                                                                                                                                                       |
| [5965564122](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965564122) | Hosted Promotion Readiness | Same pass, on `966bbd61`.                                                                                                                                                                               |
| [5965564320](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965564320) | PR Config Audit            | Same pass, on `966bbd61`.                                                                                                                                                                               |
| [5965564504](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965564504) | PR Harness Audit           | Same pass, on `966bbd61`.                                                                                                                                                                               |
| [5965578107](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965578107) | Security Evidence          | Same pass, on current head `61a18c32`.                                                                                                                                                                  |
| [5965578227](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965578227) | PR Risk Taxonomy           | Same two buckets and the same three paths, on `61a18c32`.                                                                                                                                               |
| [5965578369](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965578369) | Reference Set Readiness    | Same 0/7 gap list, on `61a18c32`.                                                                                                                                                                       |
| [5965578541](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965578541) | Hosted Promotion Readiness | Same pass, on `61a18c32`.                                                                                                                                                                               |
| [5965578744](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965578744) | PR Config Audit            | Same pass, on `61a18c32`.                                                                                                                                                                               |
| [5965578934](https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965578934) | PR Harness Audit           | Same pass, on `61a18c32`.                                                                                                                                                                               |

The reference-set rows, repeated in 5965419271, 5965563968, and 5965578369, are:

| Area                     | ECC next step                                                                     |
| ------------------------ | --------------------------------------------------------------------------------- |
| Deep analyzer corpus     | Analyzer fixture, golden, benchmark, or reference-set files                       |
| RAG/evaluator comparison | Retrieval or evaluator fixtures with expected ranking                             |
| PR salvage/review corpus | Stale-PR, review-thread, reopen, or salvage cases                                 |
| Discussion triage corpus | Fixtures for informational, answered, and no-response classes                     |
| Harness compatibility    | Cross-harness evidence for Claude, Codex, OpenCode, Zed, dmux, and agent surfaces |
| Security evidence        | SBOM, SARIF, audit report, or AgentShield pack                                    |
| CI failure-mode evidence | Captured CI logs, dry-run fixtures, or troubleshooting docs                       |

Hosted promotion (5965419445, 5965564122, 5965578541) compares the diff with
`src/analyzers/fixtures/evaluator-rag-corpus.ts`. That path is not in this
repository. The audit reports zero matching scenarios and zero cached hosted
jobs.

## Themes

### Passed security, config, harness, and promotion gates

- **Severity:** None. These audits succeeded on every round.
- **Smallest fix:** None.
- **Files:** `.github/workflows/bench-pr.yml` was the only config file ECC
  scanned. The security gate, in enforce mode, reported no missing
  scanner-evidence signal on the same five-file diff.

### Checks publication

- **Severity:** Outside this repository. The sentence is an ECC app permission,
  repeated on all 18 comments. It is not a finding about the diff.
- **Smallest fix:** An app owner enables Checks read and write, and the
  installation owner approves that permission. No commit on
  `cursor/pr49-snapshot-077b` can publish those checks.
- **Files:** None.

### Security taxonomy on the bench caller

- **Severity:** Low. The taxonomy is neutral and asks for a review. The
  enforce-mode security gate on the same commits already passed.
- **What changed:** `bench-pr.yml` now calls `./.github/workflows/bench.yml`.
  The previous line called
  `kenn-io/agentsview/.github/workflows/bench.yml@main`. `permissions: read-all`
  is unchanged. The called workflow sets `permissions: contents: read` and
  runs `make bench-gate` plus `cmd/benchgate`. The header in `bench-pr.yml`
  states why the `@main` pin failed: while the upstream file existed it
  required `BENCH_GATE_HEAVY` under `set -u`, which this Makefile does not
  emit, and after agentsview #1667 removed `bench.yml` the caller failed
  before any job started.
- **Smallest fix:** Keep the in-repo `workflow_call`. That call narrows the
  trust boundary to this repository's `bench.yml` and drops a floating
  upstream ref. Do not add a scanner, SBOM, or SARIF upload to satisfy the
  taxonomy label.
- **Files:** `.github/workflows/bench-pr.yml`, `.github/workflows/bench.yml`.

### CI/CD recommendation

ECC lists three signals on `bench-pr.yml`,
`internal/sync/watch_backend_fsnotify.go`, and
`internal/sync/watch_backend_fsnotify_test.go`.

#### Regression coverage may lag

- **Severity:** None for this diff. The signal is generic and does not match the
  Go change.
- **Evidence already on the branch:** `forgetRemovedSubtree` calls
  `watchOps.Remove` and ignores `fsnotify.ErrNonExistentWatch`.
  `TestFSNotifyBackendRemovalEventRemovesInvalidatedNativeWatch` drives a
  remove event through a counter that returns `ErrNonExistentWatch`, and
  asserts one `Remove` call, no reported error, pruned ownership for the
  removed directory, a retained root watch, and a returned budget slot.
  `TestFSNotifyBackendRootLossTransfersExactScopeToPolling` now asserts that
  `watchOwners` is empty after the loss transfer.
- **Smallest fix:** None. Do not add another test for the same remove path.
- **Files:** `internal/sync/watch_backend_fsnotify.go`,
  `internal/sync/watch_backend_fsnotify_test.go`.

#### Workflow changes without failure-mode evidence

- **Severity:** Low. The failure modes of the old pin are already written in the
  `bench-pr.yml` header. `docs/internal/performance-gates.md` already
  documents `make bench-gate-config`, partial baselines, and the count/time
  handoff. It does not yet say that pull requests enter that workflow through
  the in-repo caller.
- **Smallest fix:** Add one short subsection to
  `docs/internal/performance-gates.md` stating that `bench-pr.yml` calls
  `./.github/workflows/bench.yml`, that count and time still come from
  `make bench-gate-config`, and that the retired `@main` pin failed in the two
  ways the workflow header already names. Point at the existing header rather
  than pasting a second copy of the history. Do not add captured logs or a
  dry-run fixture; the gate is a `workflow_call` plus `make bench-gate`, and a
  synthetic log would not lock the caller to the Makefile.
- **Files:** `docs/internal/performance-gates.md`. Read-only context:
  `.github/workflows/bench-pr.yml`, `.github/workflows/bench.yml`, `Makefile`
  (`bench-gate-config`).

#### Dependency or CI drift after merge

- **Severity:** None beyond the pin that is already in the diff.
- **Smallest fix:** Leave the caller on `./.github/workflows/bench.yml`.
  `bench.yml` already evaluates `make -s bench-gate-config` on the
  pull-request head and passes `BENCH_GATE_COUNT` and `BENCH_GATE_TIME` into
  the merge-base run. A second pin, a new checksum, or a dependency bump does
  not answer this signal.
- **Files:** `.github/workflows/bench.yml`, `Makefile`.

### Reference-set readiness

- **Severity:** Neutral scanner output. Six of the seven areas describe ECC
  product corpora. This repository is the Periscope session viewer. It has no
  `src/analyzers/` tree, and hosted promotion already reported that no
  evaluator scenario matched the diff.
- **Smallest fix:** Do not add those corpora. The one overlapping area, CI
  failure-mode evidence, is the documentation paragraph in the CI/CD theme.
  Troubleshooting prose for stale Actions runs is already in
  `docs/2026-09-02-ci-triage-and-branch-verification-lesson.md`. ECC still
  marks the area missing because it asks for corpus-shaped files. Matching
  that filename heuristic is not a product change.

| Area                     | Disposition                                                                                                                                  |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Deep analyzer corpus     | Out of scope. No analyzer product in this repo.                                                                                              |
| RAG/evaluator comparison | Out of scope. The cited corpus file is absent, and hosted promotion matched nothing.                                                         |
| PR salvage/review corpus | Out of scope. Queue-cleanup automation is not this pull request.                                                                             |
| Discussion triage corpus | Out of scope. Discussion classification is not this pull request.                                                                            |
| Harness compatibility    | Out of scope. The harness audit of `bench-pr.yml` already passed. Claude, Codex, OpenCode, Zed, and dmux adapters are not part of this diff. |
| Security evidence packs  | Out of scope. The security gate passed. SBOM, SARIF, and AgentShield packs are skipped under the security theme.                             |
| CI failure-mode evidence | In scope only as the one paragraph in `docs/internal/performance-gates.md`. The workflow header and the CI-triage lesson already exist.      |

## Recommended order

1. Close the passed gates, the Checks-publication note, the false coverage-lag
   signal, and the drift signal. They need no patch.
1. If the pin rationale should sit next to the gate contract, add the single
   subsection to `docs/internal/performance-gates.md` on
   `cursor/pr49-snapshot-077b`.
1. Leave the six ECC corpora, scanner packs, and the Checks permission with
   their owners.

## Explicit skips

| Item                                                                             | Why it is skipped                                                                                                                           |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| Security evidence gate (5965418993, 5965563700, 5965578107)                      | Already passed, including on the current head.                                                                                              |
| Hosted promotion (5965419445, 5965564122, 5965578541)                            | Already passed. Zero scenarios. The corpus path is not in this repo.                                                                        |
| Config audit (5965419633, 5965564320, 5965578744)                                | Already passed for `bench-pr.yml`.                                                                                                          |
| Harness audit (5965419789, 5965564504, 5965578934)                               | Already passed for `bench-pr.yml`.                                                                                                          |
| "Regression coverage may lag"                                                    | False for this diff. The remove path has a focused test, and the root-loss test asserts cleared ownership.                                  |
| "Dependency or CI drift" as new work                                             | The in-repo `workflow_call` is the drift fix. Count and time already come from `bench-gate-config`.                                         |
| Deep analyzer, RAG/evaluator, PR salvage, discussion triage, and harness corpora | Out of scope. They are ECC reference sets, not Periscope behavior.                                                                          |
| SBOM, SARIF, or AgentShield packs                                                | Out of scope. The enforce-mode gate found no scanner-evidence gap, and the workflow diff adds no secret, permission, or third-party action. |
| Checks read/write publication                                                    | Out of scope. GitHub App permission, not a tree change.                                                                                     |
| Rewriting pull request #49 or `experiment/upstream-merge-measurement-20260902`   | Forbidden. Those refs stay as they are.                                                                                                     |
| Further edits to the fsnotify remove path                                        | Already implemented and tested on this branch.                                                                                              |

## Non-goals

- Turning the 0/7 reference-set score into 7/7.
- Adding a Go feature, a workflow permission change, or a new benchmark.
- Merging pull request #80, commenting on GitHub, or retargeting pull request
  #49.
