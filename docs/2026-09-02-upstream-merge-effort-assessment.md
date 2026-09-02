---
title: Upstream merge effort assessment — 2026-09-02
description: Real conflict count and risk-tiered breakdown from an actual (aborted) merge attempt against upstream AgentsView, with a recommendation on how to structure the effort if pursued
---

# Upstream merge effort assessment — 2026-09-02

**Status:** Measurement only. No conflicts were resolved in this pass.
**Author:** Claude Sonnet 5, per explicit request to measure (not attempt)
a full upstream integrative merge, as a companion to
[#48](https://github.com/diazMelgarejo/periscope/pull/48) (the
docs/assets-only fix).

## Where periscope last synced

The most recent upstream integrative merge on record is
[#39](https://github.com/diazMelgarejo/periscope/pull/39) ("Reconcile
periscope onto current AgentsView upstream (third integrative merge)"),
merged 2026-07-30, which synced periscope to
`kenn-io/agentsview@a421fe8d` ("fix(pricing): refresh daemon catalog
daily (#1285)"). No upstream merge has landed on `merged` since.

## The delta today

```text
git diff --shortstat a421fe8d kenn-io/agentsview/main
  1523 files changed, 270941 insertions(+), 31565 deletions(-)

182 commits since a421fe8d (2026-07-30 -> 2026-09-01)
```

Rough breakdown by area (commit count touching each path):

| Area | Commits |
| --- | --- |
| `cmd/` + `internal/` (core app logic) | 136 |
| `docs/` | 94 |
| `frontend/` | 53 |

## Genuinely new subsystems upstream added

Not just file churn in existing packages -- these `internal/` packages
did not exist at `a421fe8d` and are new since:

- `internal/capture`
- `internal/e2e`
- `internal/jsonutil`
- `internal/rawcapture`
- `internal/rawcheckpoint`
- `internal/rawclient`
- `internal/rawpath`
- `internal/rawsync`
- `internal/rawupload`
- `internal/rawwatch`
- `internal/usagefacts`

The `raw*` family in particular reads as a whole new capture/sync/upload
pipeline, not an incremental change to something periscope already has.
Also separately confirmed (via the docs/assets work in #48): upstream's
Insights page was renamed/rewritten into a substantially larger
"Recall (Experimental)" feature -- periscope has already partially
ported Recall (`internal/server/recall.go`, `internal/config/recall.go`)
but still carries the old Insights code alongside it, so periscope's
own state is itself mid-migration on that axis already.

## Actual merge attempt: real conflict count

Ran `git merge --no-commit --no-ff kenn-io/agentsview/main` against
`origin/merged` and captured the result, then aborted (no broken state
was left in any branch):

**60 files in genuine content conflict** (both sides changed the same
lines), out of 1523 upstream-touched files. Auto-merge succeeded
cleanly for everything else upstream changed that periscope hadn't
also touched.

Conflicted files, grouped by what they likely require:

**Core application logic (highest-risk, needs real understanding of
both sides' intent, not just conflict-marker resolution):**
```text
cmd/periscope/artifact_sync.go
cmd/periscope/capture.go
cmd/periscope/cli.go
cmd/periscope/duckdb.go
cmd/periscope/export_reporting.go
cmd/periscope/live_activity.go
cmd/periscope/pg.go
cmd/periscope/pg_raw_sync.go
cmd/periscope/raw_sync.go
cmd/periscope/session_get.go
cmd/periscope/sync_lifecycle.go
desktop/src-tauri/src/lib.rs
internal/artifact/manifest_session.go
internal/config/config.go
internal/db/schema.sql
internal/db/sessions.go
internal/postgres/usage.go
internal/server/server.go
```

**Test files (still need real review, but lower blast-radius than
production code):**
```text
cmd/periscope/archive_query_backend_test.go
cmd/periscope/archive_write_backend_test.go
cmd/periscope/artifact_sync_test.go
cmd/periscope/capture_test.go
cmd/periscope/daemon_push_test.go
cmd/periscope/daemon_test.go
cmd/periscope/export_reporting_test.go
cmd/periscope/live_activity_test.go
cmd/periscope/parse_diff_test.go
cmd/periscope/pg_raw_sync_test.go
cmd/periscope/poll_coordinator_scope_test.go
cmd/periscope/polling_scope_identity_test.go
cmd/periscope/raw_sync_test.go
cmd/periscope/serve_runtime_test.go
cmd/periscope/session_get_test.go
cmd/periscope/symlink_polling_scope_test.go
cmd/periscope/watch_obligations_scope_test.go
internal/db/store_contract_test.go
internal/duckdb/analytics_usage_test.go
internal/export/pricing_test.go
internal/parser/codex_parser_test.go
internal/parser/devin_provider_test.go
internal/server/huma_routes_remote_sync_internal_test.go
internal/service/session_usage_rollup_test.go
internal/sync/parse_retention_test.go
internal/sync/verified_source_gate_integration_test.go
```

**Fixture / data / lockfile (usually mechanical, but reporting fixtures
need semantic review, not blind regeneration):**
```text
cmd/periscope/testdata/reporting/day-v1.json
cmd/periscope/testdata/reporting/day-v2.json
cmd/periscope/testdata/reporting/digest-v1.json
cmd/periscope/testdata/reporting/digest-v2.json
cmd/periscope/testdata/reporting/hour-v1.json
cmd/periscope/testdata/reporting/hour-v2.json
cmd/periscope/testdata/reporting/manifest.sha256
frontend/package-lock.json
go.sum
internal/pricing/snapshot/.gitignore
```

**Config / meta / frontend:**
```text
.github/workflows/ci.yml
AGENTS.md
README.md
frontend/package.json
frontend/scripts/generate-api-client.mjs
frontend/src/lib/components/modals/AboutModal.svelte
```

## Comparison to the last integrative merge

PR #39's own body documents 6 named, individually-reasoned conflict
resolutions (each requiring understanding *why* each side changed the
code, not just picking one side) across a smaller upstream delta than
this one, plus a full verification pass: `go build`/`go vet` clean, 3
targeted `go test` packages, `svelte-check` 0 errors, and
`vitest run` 143/143 files / 2146/2146 tests. That merge is described
there as "the third major AgentsView -> merged integrative absorption."

This delta is larger (182 vs. an unstated but smaller commit count,
1523 files touched, 11 new packages including a new raw-capture
subsystem) and has 60 conflicting files touching core sync/capture/
config/schema logic, not just tests.

## Recommendation

Not a one-shot task. If pursued, structure it the way #39 itself
frames its own lineage ("third integrative merge") -- as a dedicated,
reviewed effort with:

1. A real 3-way merge (not squash-import) so history and blame stay
   intact, matching this repo's established convention.
2. Conflict resolution grouped and reasoned file-by-file, as PR #39's
   body models, not blind "ours"/"theirs".
3. Full verification before requesting review: `go build`/`go vet`,
   the Go test suite, `svelte-check`, `vitest run` -- matching PR #39's
   own bar.
4. Explicit review of whether periscope should absorb the new `raw*`
   capture/sync/upload subsystem at all, or treat it as
   out-of-scope for this fork (same kind of judgment call this repo
   already made keeping Insights alongside a partially-ported Recall).

Given the size, this is a multi-day effort for a careful reviewer, not
a single automated pass -- consistent with what this repo's own
history shows integrative merges actually cost.
