# Layer-2 integrative synthesis analysis (local only — not pushed)

> **Date:** 2026-07-28  
> **Branch:** `merged-local-on-origin` (worktree `periscope-recovery-layer2`)  
> **Base:** `origin/merged` @ `44593b77`  
> **Compared:** `origin/merged-local-reanchored` @ `bec3eeb9`

## Method

Integrative harmonizing synthesis per `integrative-merge.md` — not literal rebase,
not `ours`/`theirs`, not cherry-pick replay of 20 commits.

| Mode | Paths | Resolution |
|------|-------|------------|
| **superset** | ECC bundle, attribution guards, rename catalogue, cursor rules | Keep `origin/merged` (34 paths local line never had) |
| **architecturally-correct** | `desktop/src-tauri/src/lib.rs`, sidecar scripts, `.gitignore`, workflow tests | Keep `origin/merged` (`sidecar("periscope")`, PR #14) — local `agentsview` stems are stale merge residue |
| **union** | `AGENTS.md` Cursor Cloud commit section | Keep `origin/merged` section |
| **synthesize** | `frontend/package.json` | `marked` runtime dep @ `18.0.3` (local intent) + `svelte` `^5.55.9` (origin newer) |
| **union** | `docs/ARCHITECTURE.md` | Keep origin body + rename catalogue links + add L4 integration cross-link |
| **additive** | `docs/INTEGRATION-ORAMASYS-STACK-PLAN.md` | Add from working tree |

## Why cherry-pick / blind rebase failed

Commit 1 of the local line (`merge upstream PR #352`) duplicates content already
landed via `6cf2f38f` dual-pedigree reanchor on `origin/merged`. Remaining 19
commits are mostly **empty or conflicting** against the integrative tree — not
missing semantic work.

## Tree facts

| Comparison | Result |
|------------|--------|
| Files only on `merged-local-reanchored` | **0** (strict subset of origin tree) |
| Files only on `origin/merged` | **34** (ECC, guards, catalogue, …) |
| Modified both sides | **10** (resolved above) |
| `PROGRESS.md`, `sync-upstream.sh`, `cmd/periscope/main.go` | **Identical blobs** |

## Layer-2 delta vs `origin/merged`

Five paths in commit `2cddec88`:

- `docs/INTEGRATION-ORAMASYS-STACK-PLAN.md` (new)
- `docs/INTEGRATION-SYNTHESIS-LAYER2-ANALYSIS.md` (new)
- `docs/ARCHITECTURE.md` (L4 integration cross-link)
- `frontend/package.json` (harmonized `marked` / `svelte`)
- `frontend/package-lock.json` (lock refresh)

**Not pushed.**

## Verification gates (2026-07-28)

| Gate | Result |
|------|--------|
| `npm install --package-lock-only` + lock committed | ✅ |
| `go test -tags fts5 ./...` | ✅ all packages `ok` (~65s; `internal/server` slowest at ~24s) |
| `git diff origin/merged..HEAD --stat` | ✅ 5 files, +262 / −8 lines |

**Ready for push review** — no remaining local smoke blockers on Go side.
Frontend `npm test` / `npm run check` not run (docs-only delta except package.json).

