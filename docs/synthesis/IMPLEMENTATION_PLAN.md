# agentsview+periscope — Staged Integrative Synthesis Plan

**Branch:** `cursor/agentsview-plus-periscope-f559`  
**PR:** [#29](https://github.com/diazMelgarejo/periscope/pull/29) → `merged`  
**Method:** oramasys-method integrative merge (synthesize, never amputate)  
**Started:** 2026-07-29

## Goal

Unify `merged` (Periscope fork Layer 3) with `cursor/agentsview-purified-onto-kenn-f559`
(kenn-io replay + PR #26 upstream stack) using **path-scoped passes**, not monolithic
`-X ours/theirs`.

## Source refs

| Ref | SHA | Role |
|-----|-----|------|
| `merged` | `12d23c2e` | Layer 3 canonical base |
| `purified+PR26` | `ff8cd5b3` | Incoming upstream replay |
| merge-base | `6c3317ad` | agentsview mirror tip |

## Pass checklist

### Pass 0 — Setup ✓

- [x] PR #26 merged into purified
- [x] Experiment A branch + PR #29 opened
- [x] Conflict inventory (735 paths, symmetric)
- [x] This implementation plan committed

### Pass 1 — Layer 1 upstream (parser, sync, postgres, db)

**Mode:** superset / architecturally-correct  
**Take from:** purified  
**Paths:**

- [ ] `internal/parser/` (all except periscope-owned extensions if any)
- [ ] `internal/sync/`
- [ ] `internal/postgres/`
- [ ] `internal/db/schema.sql`, migrations, artifact tables from PR #1251
- [ ] `internal/remotesync/` (upstream #1283)

**Keep from merged:** periscope-specific db columns if documented in ARCHITECTURE.md Layer 2

**Verify:** `go test ./internal/parser/... ./internal/sync/... ./internal/postgres/... -short`

### Pass 2 — PR #26 feature replay (artifact, duckdb, omnigent)

**Mode:** additive  
**Take from:** purified (already contains #1274, #1251, #1284)

- [ ] `internal/artifact/`
- [ ] `internal/config/` duckdb tilde expansion
- [ ] `internal/pathutil/`
- [ ] `internal/parser/omnigent*.go`
- [ ] `cmd/periscope/` duckdb/import/session paths (module path = periscope)

**Verify:** `go test ./internal/artifact/... ./internal/config/... -short`

### Pass 3 — Layer 3 identity invariants ✓

**Mode:** api-correct — keep merged  
**Paths (must remain periscope):**

- [x] `go.mod` / `go.sum` → `github.com/latentsignal-org/periscope`
- [x] `cmd/periscope/` binary name (no `cmd/agentsview/`)
- [x] `scripts/install.sh`, `scripts/install.ps1`, `scripts/release.sh`, `scripts/sync-upstream.sh`
- [x] `.github/workflows/ci.yml`, `ci-pr.yml` (fork paths)
- [x] `scripts/git/verify-staged-for-commit.sh` (copied from purified/PR26)
- [x] `PERISCOPE_OWNED` list in sync-upstream.sh

**Extend:** sync-upstream.sh kenn-io Layer 1 auto-resolution comment block
(`internal/parser`, `internal/sync`, `internal/postgres` → take purified)

**Verify:** `rg 'wesm/agentsview' --glob '*.go'` → zero; `go build -tags fts5 ./cmd/periscope` → BUILD_OK

### Pass 4 — Frontend synthesize (context + kit-ui)

**Mode:** synthesize  
**Blend:**

- [x] Keep `frontend/src/lib/components/context/` from merged (Layer 2)
- [x] Take kit-ui migration from purified PR #26 where non-conflicting
- [x] Union `frontend/src/lib/stores/`, router changes

**Verify:** `cd frontend && npm test` (or vitest subset)

### Pass 5 — Docs union + ECC path-scoped replay

**Mode:** union + path-scoped replay (PR #25 precedent)

- [x] Union `docs/` — keep merged periscope guides + purified upstream fixes
- [x] ECC: replay only harmonized paths (SKILL.md mirrors, instincts) — skip timestamp-only JSON
- [x] Update synthesis progress in this file

**Verify:** `make docs-check`

### Pass 6 — Full gate

- [ ] `make test-short`
- [ ] `make lint` (or CI subset)
- [ ] Update PR #29 body (append only)
- [ ] PT `.agent` working memory + `learn.py` lesson

## Progress log

| Pass | Status | Commit | Agent | Notes |
|------|--------|--------|-------|-------|
| 0 | done | `d42bd53f` | orchestrator | manifest |
| 1 | in_progress | — | pass1-agent | — |
| 2 | pending | — | pass2-agent | — |
| 3 | done | `4321d36b` | pass3-agent | identity invariants verified vs merged; sync-upstream Layer 1 docs; verify-staged copied |
| 4 | done | — | pass4-agent | kit-ui Card/EmptyState in context; kept merged session prop init |
| 5 | done | (this commit) | pass5-agent | docs union + ECC replay (merged superset kept) |
| 6 | pending | — | orchestrator | — |

## Doctrine

Per `integrative-merge.md`: simulate → classify → harmonize → verify → commit.
Never `git checkout --ours/theirs` on whole trees. Archive, don't delete.
