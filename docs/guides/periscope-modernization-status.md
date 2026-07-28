# Periscope modernization status

**Updated:** 2026-07-28  
**Base commit:** `2b6e5128` (3way modernization replay)  
**Integration branch:** `merged`  
**Replaces:** historical `PROGRESS.md` completion ledger (archive only — not active truth)

---

## Summary

The fork maintains **exact mirrors** of `kenn-io/agentsview` and
`latentsignal-org/periscope`, with **integrative `merged`** carrying current
AgentsView foundation plus additive Periscope product features.

This document tracks **operator-facing modernization** (tooling, docs, install,
sync safety). Product feature work remains in `docs/periscope-v1-plan.md` and
related specs.

---

## Completed in this replay (docs + scripts scope)

| Item | Status | Notes |
| --- | --- | --- |
| `docs/ARCHITECTURE.md` | Ported | kenn-io/latentsignal canon; SessionVitals invariant |
| Build design + plan docs | Ported | Historical May 2026 + 2026-07 epilogue |
| `docs/guides/periscope-upstream-sync-blueprint.md` | Updated | SessionVitals alignment |
| `scripts/sync-upstream.sh` | Ported | dry-run, simulate, non-interactive, no auto-push |
| `scripts/install.sh` | Ported | Periscope product + agentsview compat |
| `scripts/install_test.sh` | Updated | Periscope URLs + legacy env aliases |
| Release tag convention | Documented | `v{semver}-{8-char-sha}` from 5bd2e8a |

---

## In progress (outside this scoped replay)

| Area | State | Tracker |
| --- | --- | --- |
| `cmd/agentsview` → product `periscope` in Makefile/CI | Partial | rename catalogue |
| Desktop sidecar `periscope-*` artifacts | Partial | desktop workflow PRs |
| Full AgentsView tree on `merged` | Replay ongoing | upstream blueprint §4 |
| `release.yml` archive names | Upstream-shaped | rename `rename_build_release` |

---

## Blockers / operator actions

1. **No remote mutation without authorization** — mirror refresh needs backup tag
   + lease SHA; scripts enforce this.
2. **Dual pedigree** — do not rebase `merged` onto one mirror only; use blueprint
   disposable-worktree replay.
3. **Desktop signing** — unsigned CI builds expected until
   `TAURI_SIGNING_PRIVATE_KEY` + `PERISCOPE_UPDATER_PUBKEY` are configured
   (72431d3b).
4. **First Periscope-tagged release on diazMelgarejo** — install script falls back
   to legacy `agentsview_*` archives until `periscope_*` assets ship.

---

## Quick commands

```bash
# Preview upstream movement (no writes)
./scripts/sync-upstream.sh --dry-run --source kenn
./scripts/sync-upstream.sh --dry-run --source latentsignal

# Merge probe in disposable worktree
./scripts/sync-upstream.sh --simulate --source kenn

# Install script tests
./scripts/install_test.sh

# Release tag (operator, after verification)
COMMIT=$(git rev-parse --short=8 HEAD)
git tag -a "v0.29.2-periscope.2-${COMMIT}" -m "Release v0.29.2-periscope.2-${COMMIT}"
```

---

## Canonical references

| Doc | Role |
| --- | --- |
| [`periscope-upstream-sync-blueprint.md`](./periscope-upstream-sync-blueprint.md) | Sync policy |
| [`ARCHITECTURE.md`](../ARCHITECTURE.md) | Matryoshka + invariants |
| [`agentsview-to-periscope-rename-catalogue.md`](./agentsview-to-periscope-rename-catalogue.md) | Rename decision tree |
