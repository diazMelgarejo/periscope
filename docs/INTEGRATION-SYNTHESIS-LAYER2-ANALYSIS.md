# Layer-2 integrative synthesis analysis

> **Date:** 2026-07-28  
> **Branch:** `merged-local-rebased-on-origin` (worktree `periscope-recovery-layer2`)  
> **Tip:** `git rev-parse origin/merged-local-rebased-on-origin` after fetch  
> **Base:** `origin/merged` @ `44593b77`  
> **Compared:** `origin/merged-local-reanchored` @ `bec3eeb9`  
> **Doctrine:** [integrative-merge.md](https://github.com/diazMelgarejo/orama-system/blob/main/bin/orama-system/skills/oramasys-method/references/integrative-merge.md) (orama-system sibling repo)

## Method

Integrative harmonizing synthesis per integrative-merge — not literal rebase,
not `ours`/`theirs`, not cherry-pick replay of 20 commits.

| Mode | Paths | Resolution |
|------|-------|------------|
| **superset** | ECC bundle, attribution guards, rename catalogue, cursor rules | Keep `origin/merged` (34 paths local line never had) |
| **architecturally-correct** | `desktop/src-tauri/src/lib.rs`, sidecar scripts, `.gitignore`, workflow tests | Keep `origin/merged` (`sidecar("periscope")`, PR #14) — local `agentsview` stems are stale merge residue |
| **union** | `AGENTS.md` Cursor Cloud commit section | Keep `origin/merged` section |
| **synthesize** | `frontend/package.json` | `marked` runtime dep @ `18.0.3` (local intent) + `svelte` `^5.55.9` (origin newer) |
| **union** | `docs/ARCHITECTURE.md` | Keep origin body + rename catalogue links + add L4 integration cross-link |
| **additive** | `docs/INTEGRATION-ORAMASYS-STACK-PLAN.md` | Add from working tree |
| **architecturally-correct** | `frontend/src/App.svelte` | Remove dead `ActivityMinimap` block (component deleted upstream; SessionVitals replaced it) |
| **architecturally-correct** | Context viz TS strictness | Fix `ContextWindowBlocks` / `ContextTimeline` types so `svelte-check` passes |

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

Docs + package harmonization + frontend strictness fixes (see `git diff origin/merged..HEAD --stat`).

## Verification gates (2026-07-28)

| Gate | Result |
|------|--------|
| `npm install` / lock committed | ✅ |
| `go test -tags fts5 ./...` | ✅ all packages `ok` (~65s) |
| `npm run check` (`svelte-check`) | ✅ 0 errors, 4 warnings (pre-existing CSS/a11y) |
| `npm test` (`vitest run`) | ✅ 64 files, 1127 tests passed (~15s) |
| `git diff origin/merged..HEAD --stat` | ✅ reviewed before push |

## Branch lineage

```text
origin/merged (44593b77)
  └── merged-local-rebased-on-origin   ← integrative synthesis + L4 docs + frontend fixes

origin/merged-local-reanchored (bec3eeb9)   ← layer-1 tree twin salvage (alternate history)
```
