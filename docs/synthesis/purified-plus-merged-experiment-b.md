# Synthesis experiment B — `purified+PR26` ← `merged`

**Branch:** `cursor/purified-plus-merged-f559`  
**Base for PR:** `cursor/agentsview-purified-onto-kenn-f559`  
**Incoming:** `merged` (Periscope fork Layer 3 + ECC + context features)

## Intent

Canonical **upstream-modernized line** (kenn-io replay on `agentsview` mirror) remains
the merge base. Graft Periscope fork enhancements (rename, release pipeline, context
page, ECC, JetBrains lifecycle) onto the purified tree.

## Divergence (simulated 2026-07-29)

| Metric | Value |
|--------|-------|
| Merge-base | `6c3317ad` (agentsview mirror tip) |
| Commits only on purified | 25 |
| Commits only on merged | 76 |
| Files changed (tree diff) | 2133 |
| Simulated merge conflicts | **735** paths (symmetric with experiment A) |

## Conflict hotspots (top)

Same distribution as experiment A — conflict count is direction-independent;
**resolution bias** differs.

## Resolution bias (oramasys-method)

1. **Upstream replay wins** for parser/sync/postgres/schema migrations.
2. **Merged wins** for `go.mod` module path, `cmd/periscope`, branding, install scripts.
3. **Synthesize** frontend: context components + kit-ui modernization from both sides.
4. **Union** docs: keep purified upstream docs + merged periscope-specific guides.
5. **Architecturally-correct:** PR #26 CI fixes (local workflow, hydrate from origin) apply to both.

## Status

Manifest-only commit. Full harmonization is a multi-pass integrative merge (Mode 2),
not a single `-X ours/theirs`.
