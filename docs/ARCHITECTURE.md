---
title: Periscope architecture
description: Matryoshka model, branch roles, and fork invariants for diazMelgarejo/periscope
---

# Periscope fork — architecture and build reference

> **Status:** Living document. Update after every upstream replay and fork enhancement.  
> **Canonical integration branch:** `merged`  
> **Last updated:** 2026-07-28

**Operator policy:** [`docs/guides/periscope-upstream-sync-blueprint.md`](guides/periscope-upstream-sync-blueprint.md)  
**Rename checklist:** [`docs/guides/agentsview-to-periscope-rename-catalogue.md`](guides/agentsview-to-periscope-rename-catalogue.md)  
**Modernization status:** [`docs/guides/periscope-modernization-status.md`](guides/periscope-modernization-status.md)

---

## The matryoshka model

Periscope is built in three nested layers. Each layer wraps the previous one with
additive, non-destructive enhancements. The integration line (`merged`) must keep
the **current AgentsView foundation** plus **additive Periscope product**
innovations.

```
╔══════════════════════════════════════════════════════════════════╗
║  Layer 3 — diazMelgarejo/periscope (`merged`)                   ║
║  Product: Periscope · Module: go.kenn.io/agentsview (modern)    ║
║                                                                  ║
║  + Fork tooling: scripts/sync-upstream.sh, scripts/install.sh    ║
║  + Release/install branding toward `periscope` binary/artifacts  ║
║  + JetBrains plugin lifecycle (auto-start/stop backend)          ║
║  + Dual-pedigree integrative merge policy (see blueprint)         ║
║  + Commit-suffixed release tags: v{semver}-{8-char-sha}          ║
║                                                                  ║
║  ┌──────────────────────────────────────────────────────────┐   ║
║  │  Layer 2 — latentsignal-org/periscope (`main` mirror)     │   ║
║  │  Canonical remote: https://github.com/latentsignal-org/   │   ║
║  │                    periscope                              │   ║
║  │                                                          │   ║
║  │  + ContextPage (context window visualizer)               │   ║
║  │  + SessionVitals + ActivityLane (session vitals UI)      │   ║
║  │  + internal/summarize + internal/llm (LLM summaries)   │   ║
║  │  + guidance client/model/cache (context guidance)        │   ║
║  │  + jetbrains-plugin/                                     │   ║
║  │  + API routes: /context, /context/timeline, /summarize   │   ║
║  │  + ModelContextWindowTokens / HasModelContextWindowTokens│   ║
║  │                                                          │   ║
║  │  ┌────────────────────────────────────────────────────┐  │   ║
║  │  │  Layer 1 — kenn-io/agentsview (`agentsview` mirror) │  │   ║
║  │  │  Canonical remote: https://github.com/kenn-io/      │  │   ║
║  │  │                    agentsview                       │  │   ║
║  │  │                                                    │  │   ║
║  │  │  Session indexing + SQLite storage               │  │   ║
║  │  │  Parser framework (internal/parser/types.go)     │  │   ║
║  │  │  Registered agents (Claude, Codex, Gemini, …)    │  │   ║
║  │  │  Go HTTP server + Svelte 5 frontend              │  │   ║
║  │  │  Signals engine, sync engine, recall, vectors    │  │   ║
║  │  │  GitHub Actions release + Tauri desktop          │  │   ║
║  │  └────────────────────────────────────────────────────┘  │   ║
║  └──────────────────────────────────────────────────────────┘   ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## Canonical sources and branch roles

Do **not** maintain a stale branch table here. Use the blueprint for the
current three-branch model and remote-mutation rules.

| Branch | Canonical source | Role |
| --- | --- | --- |
| `agentsview` | `kenn-io/agentsview:main` | Exact AgentsView mirror — no fork integration |
| `main` | `latentsignal-org/periscope:main` | Exact upstream Periscope mirror — no fork integration |
| `merged` | Both pedigrees + fork innovations | Integration and shipping line — agent PR target |

Hard invariants:

- Never merge `merged` into `main`.
- Never land build or integration work on either mirror branch.
- Never force-update a mirror without operator authorization, backup tag, and
  exact lease SHA (`--force-with-lease` only).
- Preserve both mirror tips in `merged` ancestry.
- Do not diagnose rewritten branch health from ahead/behind counts; use tree-twin
  checks (`reanchor_scan.sh`).

---

## Layer 1 — kenn-io/agentsview

**Role:** Upstream foundation. Prefer taking upstream improvements for parsers,
sync, storage, and shared server code. Replay or synthesize onto `merged` using
integrative merge doctrine — never wholesale `ours`/`theirs` without reading
both sides.

**Typically take upstream on conflict:**

| Area | Rule |
| --- | --- |
| `internal/parser/*` | Take upstream — new agents live here |
| `internal/sync/engine.go` | Take upstream, then reapply required Periscope extensions |
| `internal/postgres/*` | Take upstream improvements |
| `internal/db/db.go` `dataVersion` | Take upstream if higher, add Periscope migrations additively |
| `Dockerfile`, `docker-compose*.yml` | Take upstream |

---

## Layer 2 — latentsignal-org/periscope

**Role:** Periscope product features. Preserve in every upstream replay even when
upstream APIs move.

### Periscope-specific features (always preserve)

| Feature | Location | Preserve rule |
| --- | --- | --- |
| **ContextPage** | `frontend/src/lib/components/context/ContextPage.svelte` | Keep context tab routing in `App.svelte` |
| **SessionVitals** | `frontend/src/lib/components/content/SessionVitals.svelte` | Keep vitals panel; supersedes legacy ActivityMinimap |
| **ActivityLane** | `frontend/src/lib/components/content/ActivityLane.svelte` | Keep density lane inside SessionVitals |
| **Summarizer worker** | `internal/summarize/` | Keep; needs LLM credentials when enabled |
| **LLM client** | `internal/llm/` | Keep |
| **Guidance** | `internal/guidance/`, server wiring | Keep context-guidance signals |
| **JetBrains plugin** | `jetbrains-plugin/` | Keep |
| **API routes** | `/context`, `/context/timeline`, `POST /summarize` | Union with upstream routes |
| **Context exports** | `frontend/src/lib/api/types` context exports | Union with upstream exports |
| **ModelContextWindowTokens** | `internal/db/sessions.go` | Union fields with upstream `IncrementalInfo` |

### Integrative conflict examples

| Conflict site | Resolution |
| --- | --- |
| `App.svelte` | Synthesize: keep ContextPage + SessionVitals; adopt upstream layout improvements |
| `sessions.go` `IncrementalInfo` | Union Periscope token fields with upstream file metadata fields |
| `server.go` routes | Keep `/context` family and add upstream routes |
| `db.go` `dataVersion` | Take higher valid upstream version |
| Shared frontend composition | Synthesize ContextPage, SessionVitals, and upstream UI blocks |

---

## Layer 3 — diazMelgarejo/periscope

**Role:** Fork identity, tooling, release pipeline, and operator automation on
top of Layers 1+2.

| Addition | Purpose |
| --- | --- |
| `scripts/sync-upstream.sh` | Dry-run/simulate/merge helper with safety gates |
| `scripts/install.sh` | Install `periscope` from diazMelgarejo releases; legacy `agentsview` compat |
| Release workflows | Product artifacts branded `periscope` where functional |
| `PeriscopeProcessManager.kt` | JetBrains IDE binary lifecycle |
| Rename catalogue | Classify `agentsview` literals after each AgentsView replay |

**Product vs compatibility naming**

| Signal | Action |
| --- | --- |
| Git branch / remote `agentsview` | Keep — mirror name is intentional |
| Historical fixtures and docs | Keep when simulating user data |
| Binary, CI artifact, desktop sidecar | Prefer `periscope` |
| `AGENTSVIEW_*` env vars | Read for compatibility; prefer `PERISCOPE_*` |

During modernization the Go module remains `go.kenn.io/agentsview` and the build
tree may still use `cmd/agentsview/` while release/install paths transition to
the `periscope` product name.

---

## Versioning and release tags

Semver pre-release identity:

```
v0.(upstream_minor + 1).2-periscope.2
```

Tags **always embed the short commit hash** of the release commit:

```
v{semver}-{8-char-commit}   e.g.  v0.29.2-periscope.2-657a1090
```

```bash
COMMIT=$(git rev-parse --short=8 HEAD)
VERSION="v0.29.2-periscope.2"
git tag -a "${VERSION}-${COMMIT}" -m "Release ${VERSION}-${COMMIT}"
# Push only after operator review — never automatic from tooling here.
```

---

## Repeatable sync workflow

**Canonical procedure:** `docs/guides/periscope-upstream-sync-blueprint.md`

**Quick helper:** `scripts/sync-upstream.sh`

| Mode | Behavior |
| --- | --- |
| `--dry-run` | Fetch upstream, show incoming commits, verify invariants — no merge |
| `--simulate` | Disposable worktree merge probe — no branch mutation |
| default | Merge selected upstream into current branch; stops on unknown conflicts unless `--non-interactive` |

The helper merges **one** upstream source per invocation (`--source latentsignal`
or `--source kenn`). Full dual-pedigree advancement uses disposable-worktree
replay per the blueprint; the script does not auto-push or force-update mirrors.

---

## Local build

```bash
make frontend          # Svelte 5 → frontend/dist/
make build             # CGO_ENABLED=1 go build -tags fts5 → agentsview (transition)
make install           # copies binary to ~/.local/bin/
```

Serve locally:

```bash
./agentsview serve     # or periscope after rename lands in Makefile
```

---

## Install script

```bash
curl -fsSL https://raw.githubusercontent.com/diazMelgarejo/periscope/merged/scripts/install.sh | bash
```

Behaviour:

1. Detect OS and architecture.
2. Resolve latest release from `diazMelgarejo/periscope` (redirect-based, not
   rate-limited API).
3. Download `periscope_*` archive, or fall back to legacy `agentsview_*`.
4. Verify SHA256SUMS unless `PERISCOPE_SKIP_CHECKSUM=1` (or legacy
   `AGENTSVIEW_SKIP_CHECKSUM=1`).
5. Install `periscope` to `~/.local/bin/` and optionally keep an `agentsview`
   compatibility symlink.

---

## What is never removed

1. Code required by `internal/summarize/` or `internal/llm/`
2. `ModelContextWindowTokens` / `HasModelContextWindowTokens`
3. `ContextPage.svelte` and its routing
4. `SessionVitals.svelte` and `ActivityLane.svelte`
5. `/context`, `/context/timeline`, and `/summarize` API routes
6. Context type exports consumed by the frontend
7. Periscope README/operator branding on `merged`

If upstream deprecates code a Periscope feature still needs, keep it with a
`// periscope: keep — required by <feature>` comment and resolve integratively
on the next replay.

---

## Related documents

| Document | Role |
| --- | --- |
| [`periscope-upstream-sync-blueprint.md`](guides/periscope-upstream-sync-blueprint.md) | Canonical sync policy |
| [`periscope-modernization-status.md`](guides/periscope-modernization-status.md) | Current modernization snapshot |
| [`agentsview-to-periscope-rename-catalogue.md`](guides/agentsview-to-periscope-rename-catalogue.md) | Rename decision tree |
| [`superpowers/specs/2026-05-10-periscope-build-design.md`](superpowers/specs/2026-05-10-periscope-build-design.md) | Historical build design (May 2026) |
| [`superpowers/plans/2026-05-10-periscope-build-system.md`](superpowers/plans/2026-05-10-periscope-build-system.md) | Historical implementation plan |
