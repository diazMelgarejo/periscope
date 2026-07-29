# History-preserving synthesis policy

**Branch:** `cursor/agentsview-plus-periscope-f559`  
**PR:** [#29](https://github.com/diazMelgarejo/periscope/pull/29)

## Policy (2026-07-29)

Per [PERISCOPE_MODERNIZATION_PURIFIED_INTEGRATION](../../../Perpetua-Tools/.agent/memory/working/PERISCOPE_MODERNIZATION_PURIFIED_INTEGRATION_2026-07-29.md) § "never synthesize SHAs":

1. **Prefer `git merge` with two real parents** — preserves all commits from `merged` and `purified+PR26` with original SHAs.
2. **Minimize synthetic commits** — one merge commit + docs; no path-scoped replay stacks on the integration branch.
3. **Tree resolution** uses matryoshka layers, not wholesale `-X ours/theirs`.
4. **Synthetic pass work** archived on `cursor/agentsview-plus-periscope-synthetic-pass-f559` (reference only).

## Merge technique

```bash
git merge origin/cursor/agentsview-purified-onto-kenn-f559 --no-commit --no-ff
git read-tree --reset -u $(git rev-parse origin/cursor/agentsview-purified-onto-kenn-f559^{tree})
git checkout HEAD -- <PERISCOPE_OWNED paths from ARCHITECTURE.md Layer 2+3>
git commit  # records both parent SHAs
```

## Layer overlay (merged paths restored onto purified base tree)

| Layer | Paths from `merged` |
|-------|----------------------|
| 2 | `internal/summarize/`, `internal/llm/`, `frontend/src/lib/components/context/` |
| 3 | `scripts/install*`, `scripts/release.sh`, `scripts/sync-upstream.sh`, `jetbrains-plugin/`, branding docs |
| ECC | `.claude/`, `.agents/`, `.codex/` |

Purified tree retained for Layer 1 upstream (parser, sync, postgres, artifact, duckdb, huma routes, etc.).

## Progress

| Step | Status |
|------|--------|
| PR #26 merged into purified | done (`ff8cd5b3`) |
| History-preserving merge commit | done |
| `go build -tags fts5 ./cmd/periscope` | pass |
| CI gate on PR #29 | pending |
| Experiment B (#28) | probe only — do not merge |

## Abandoned approach

Path-scoped `synthesis(passN)` commits on the integration branch **violate** SHA preservation policy. They remain on `cursor/agentsview-plus-periscope-synthetic-pass-f559` for reference only.
