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
| Desktop/API/doctor product identity | Done (this replay) | User-facing name **Periscope**; bundle `io.latentsignal.periscope` |
| `~/.agentsview/desktop.env` | Preserved | Desktop shell still reads legacy path for compatibility |

---

## Release tag convention (5bd2e8a)

Fork releases **always embed the short commit hash** of the release commit.
Adopted in commit `5bd2e8a421c326a9a40e73437930ba76f475b9cb` (May 2026).

```
v{semver}-{8-char-commit}   e.g.  v0.29.2-periscope.2-657a1090
```

Semver pre-release identity on `merged`:

```
v0.(upstream_minor + 1).2-periscope.2
```

Operator tagging (after verification — never automatic from tooling):

```bash
COMMIT=$(git rev-parse --short=8 HEAD)
VERSION="v0.29.2-periscope.2"
git tag -a "${VERSION}-${COMMIT}" -m "Release ${VERSION}-${COMMIT}"
```

---

## Desktop bundle identifier

**Canonical:** `io.latentsignal.periscope` (matches `latentsignal-org/periscope` Layer 2).

The legacy AgentsView desktop bundle id `io.agentsview.desktop` is **not**
retained: in-app updater continuity would require shipping under the same
identifier, but the product rename intentionally starts a new desktop lineage.
Users on AgentsView-branded desktop builds reinstall or migrate manually; fork
updater artifacts target `diazMelgarejo/periscope`.

**Compatibility preserved:** `~/.agentsview/desktop.env` is still read for desktop
shell environment overrides (see `desktop/src-tauri/src/lib.rs`).

---

## In progress (outside this scoped replay)

| Area | State | Tracker |
| --- | --- | --- |
| `internal/db/db.go` `DataVersionTooNewError` user text | Pending | serve `--check-data-version` + `cli_test.go` |
| `internal/server/server_test.go` OpenAPI title | Pending | matches `Periscope API` in `server.go` |
| `cmd/doctor_test.go` newer-database assertion | Pending | matches `doctor.go` Periscope wording |
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
