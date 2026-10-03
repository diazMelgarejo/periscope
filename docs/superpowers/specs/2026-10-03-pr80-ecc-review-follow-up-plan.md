# PR 80 ECC scrutiny

- **Status:** Scrutinized and implemented on `cursor/pr49-snapshot-077b`.
- **Date:** 2026-10-03
- **PR:** <https://github.com/diazMelgarejo/periscope/pull/80>
- **Branch:** `cursor/pr49-snapshot-077b` (base `merged`)
- **Audited head at review:** `61a18c329f2ce49a5b1259a944179999488608ae`

## Gate

```text
AFRP: Type C | Level Expert | Mode 2
Scope: Re-scrutinize every ECC Tools comment on pull request 80 and
implement the fixes the method requires on cursor/pr49-snapshot-077b.
```

Mode 3 was not run. The Oramasys MCP namespace failed live discovery,
`POST /oramasys` on port 8001 was down, and OpenClaw on port 18789 was
down. Graceful degradation Ladders A and E say to name that miss and
continue inline in Mode 2. gbrain is not installed, and the
code-review-graph MCP namespace failed discovery, so the search chain
stopped at the diff and the audit text. GitHub code search for the audit
phrase returned HTTP 429, so the scanner filename heuristic was not
recovered.

An earlier note on this path recommended skipping every theme because a
gate said passed or a corpus looked out of scope. Audience-First Response
Protocol intent-verification trigger 2 forbids that proxy. Each theme
below was read against the comment body, the five-file diff, and the
called workflow.

## What ECC posted

Eighteen issue comments: the same six audits on `6491d41e`, `966bbd61`,
and `61a18c32`. Anchor:
<https://github.com/diazMelgarejo/periscope/pull/80#issuecomment-5965563700>.
The diff versus `merged` is `.github/workflows/bench-pr.yml`, two docs,
`internal/sync/watch_backend_fsnotify.go`, and its test. Pull request #49
and `experiment/upstream-merge-measurement-20260902` were not edited.

## Themes

### Security evidence gate

- **Citation:** oramasys-method Step 4 (verify the artifact, do not trust
  the label). orama-system Directive 4.
- **Verdict:** Already satisfied.
- **Why:** The enforce-mode comment says no scanner-evidence gap on the
  five-file diff. Reading `bench-pr.yml` agrees. The change replaces
  `kenn-io/agentsview/.github/workflows/bench.yml@main` with a local
  `workflow_call`. `permissions: read-all` is unchanged and matches the
  other pull-request dispatcher, `.github/workflows/ci-pr.yml`. The called
  workflow sets `contents: read`. The diff adds no secret, no
  `pull_request_target`, and no third-party action. An SBOM or SARIF pack
  would attest a dependency change this diff does not contain.

### Taxonomy: security-sensitive workflow path

- **Citation:** orama-system Directive 5 (elegance) and Directive 6
  (a review signal is investigated, not dismissed). The taxonomy text
  asks for scanner, code-scanning, or focused regression evidence on
  `.github/workflows/bench-pr.yml`.
- **Verdict:** Fix.
- **Change:** `TestBenchPRCallerStaysLocal` locks the `uses:` line to
  `./.github/workflows/bench.yml`, rejects `pull_request_target`, keeps
  the caller at `permissions: read-all`, and checks that `bench.yml`
  still interpolates `BENCH_GATE_COUNT` and `BENCH_GATE_TIME` from
  `make -s bench-gate-config` and does not require `BENCH_GATE_HEAVY`.

### Taxonomy: regression coverage may lag

- **Citation:** testing-without-tautologies (assert the argument and give
  the error branch its own double). oramasys-method TDD gate: a test that
  cannot fail when the new branch breaks is not evidence.
- **Verdict:** Fix.
- **Why:** `forgetRemovedSubtree` now calls `watchOps.Remove` and ignores
  only `fsnotify.ErrNonExistentWatch`. The existing removal test counted
  calls and did not record the path, so a `Remove` of the surviving root
  could still pass. The non-`ErrNonExistentWatch` report path had no test.
- **Change:** The removal test asserts `Remove` was called with the
  invalidated directory.
  `TestFSNotifyBackendRemovalEventReportsRemoveFailureAndStillPrunes`
  uses a separate double that returns a real error and asserts the error
  is reported, ownership of that directory is still dropped, the root
  watch stays, and the budget slot returns.

### Taxonomy: workflow failure-mode evidence

- **Citation:** orama-system Stage 5 (crystallize the constraint next to
  the contract). The reference-set row asks for troubleshooting docs for
  workflow failure modes, scoped to files this pull request changes.
- **Verdict:** Fix.
- **Change:** `docs/internal/performance-gates.md` now states that pull
  requests enter the gate through `bench-pr.yml`, names both ways the
  retired `@main` pin failed closed, and points at the caller contract
  test. The YAML header remains the note beside the `uses` line. The
  2026-09-02 CI triage lesson stays about stale Actions links. It is not
  the bench-pin contract.

### Taxonomy: dependency or CI drift

- **Citation:** same contract test. oramasys-method Stage 3: do not add a
  second pin, checksum, or dependency bump when the drift is "which
  workflow file runs, and which Makefile variables it reads."
- **Verdict:** Fix, by the same test. Already satisfied as a product
  change: `bench.yml` already evaluates `bench-gate-config` on the
  pull-request head. The test fails if those names diverge.

### Reference set 0/7

The comment says the score is computed from files changed in the pull
request, not from repository-level readiness. `.claude/ecc-tools.json`
already records 3/7 at repo level.
`src/analyzers/fixtures/evaluator-rag-corpus.ts` is not in this
repository.

- **Deep analyzer corpus — out of scope.** No analyzer product and no
  `src/analyzers` tree. The diff does not add one.
- **RAG/evaluator comparison — out of scope.** Hosted promotion matched
  zero scenarios. A ranking fixture would invent a corpus this diff does
  not exercise.
- **PR salvage/review corpus — out of scope.** No queue-cleanup
  automation in the five changed paths.
- **Discussion triage corpus — out of scope.** No discussion classifier
  in the five changed paths.
- **Harness compatibility — already satisfied.** The harness audit of
  `bench-pr.yml` found no harness issue. Claude and Codex adapters
  already live in the tree and are not part of this diff.
- **Security evidence packs — already satisfied.** The enforce-mode gate
  found no scanner gap. The focused regression is the caller contract
  test, not an SBOM for an unchanged `go.mod`.
- **CI failure-mode evidence — fix.** Covered by the performance-gates
  paragraph and the caller contract test. Decoy fixture filenames were
  not added to chase an unread heuristic.

Out of scope here is the Audience-First Response Protocol rule that a
negative conclusion must come from the diff and the missing product
surface, not from the word "missing" alone.

### Hosted promotion

- **Citation:** oramasys-method Step 4, plus the comment's own comparator.
- **Verdict:** Already satisfied.
- **Why:** The audit compares the diff with
  `src/analyzers/fixtures/evaluator-rag-corpus.ts` and reports zero
  matching scenarios and zero cached hosted jobs. That path is absent.
  There is no promotion scenario in this diff to implement.

### Config audit

- **Citation:** orama-system Directive 4. The comment lists one config
  file and the supported security rules.
- **Verdict:** Already satisfied.
- **Why:** Manual read of `bench-pr.yml`, not the success label. Trigger
  is `pull_request`, not `pull_request_target`. The only `uses` is the
  local workflow. Permissions stay read-only and match `ci-pr.yml`. No
  expression interpolates pull-request title or body into a shell.

### Harness audit

- **Citation:** oramasys-method search frugality: read the changed config
  the audit names.
- **Verdict:** Already satisfied.
- **Why:** `bench-pr.yml` is a GitHub Actions caller. It contains no
  Claude, Codex, OpenCode, Zed, or dmux harness keys. The audit scanned
  that one file and reported no harness issue. Adding harness adapters
  would not change this workflow.

### Checks publication footer

- **Citation:** AFRP intent-verification trigger 3: the comment states the
  mechanism. Do not invent a repository substitute.
- **Verdict:** Out of scope.
- **Why:** Every comment ends with the same sentence: check publication
  needs Checks read and write on the ECC GitHub App, approved by the
  installation owner. A workflow `permissions:` block grants
  `GITHUB_TOKEN`, not that app. No file in this branch can approve the
  installation permission.

## What changed

- `internal/sync/watch_backend_fsnotify_test.go` records the removed path
  and covers a real `Remove` error that still prunes ownership.
- `cmd/benchgate/caller_contract_test.go` locks the local bench caller
  and the `bench-gate-config` variable contract.
- `docs/internal/performance-gates.md` records the pull-request entry
  and the two retired-pin failure modes.
- This spec replaces the skip-everything note that was left uncommitted
  on the same path.

## Assumptions

- `permissions: read-all` on the caller matches `ci-pr.yml`. `bench.yml`
  already narrows the job token to `contents: read`. Narrowing only this
  caller would fork that dispatcher pattern without a failing rule.
- The ECC reference-set score will stay below 7/7 until the changed
  files include those product corpora. That is not a Periscope behavior
  gap for this diff.
- Oramasys MCP, gbrain, and code-review-graph were unavailable. The
  scrutiny used the documented inline fallback.
