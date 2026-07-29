# Periscope Fork — Architecture & Build Reference

> **Status:** Living document. Update after every upstream sync and every fork enhancement.  
> **Canonical branch:** `merged`  
> **Last updated:** 2026-07-28

**Upstream merge rename checklist:** [`docs/guides/agentsview-to-periscope-rename-catalogue.md`](guides/agentsview-to-periscope-rename-catalogue.md)
(machine index: [`agentsview-rename-index.json`](guides/agentsview-rename-index.json))

**Orchestration stack (L4):** [`docs/INTEGRATION-ORAMASYS-STACK-PLAN.md`](INTEGRATION-ORAMASYS-STACK-PLAN.md)

---

## The Matryoshka Model

Periscope is built in three nested layers. Each layer wraps the previous one with
additive, non-destructive enhancements. Understanding the boundary of each layer
is what makes upstream syncs safe and repeatable.

```
╔══════════════════════════════════════════════════════════════════╗
║  Layer 3 — diazMelgarejo/periscope (this repo, merged branch)   ║
║  Module: github.com/latentsignal-org/periscope                  ║
║  Binary: periscope  v0.29.2-periscope.2                         ║
║                                                                  ║
║  + Module/binary rename (latentsignal-org/periscope identity)   ║
║  + scripts/sync-upstream.sh (repeatable upstream merge)         ║
║  + scripts/install.sh (release download + source fallback)      ║
║  + GitHub Actions CI (release binaries on v* tag)               ║
║  + JetBrains plugin full lifecycle (auto-start/stop binary)     ║
║  + Versioning scheme: v0.(upstream_minor+1).2-periscope.2       ║
║                                                                  ║
║  ┌──────────────────────────────────────────────────────────┐   ║
║  │  Layer 2 — latentsignal-org/periscope (upstream Periscope) │   ║
║  │  fork of wesm/agentsview at PR #352 (47ca74c6)           │   ║
║  │                                                          │   ║
║  │  + ContextPage (context window visualizer, V1/V2)        │   ║
║  │  + ActivityMinimap (shown above transcript)              │   ║
║  │  + internal/summarize + internal/llm (LLM turn summaries)│   ║
║  │  + guidanceClient/guidanceModel (Phase B banner text)    │   ║
║  │  + jetbrains-plugin/ (JBCEFBrowser scaffold)             │   ║
║  │  + API routes: /context /context/timeline /summarize     │   ║
║  │  + Dev proxy: applyDevProxyHeaders / getDevProxyTarget   │   ║
║  │  + types/index.ts: exports ./context.js                  │   ║
║  │  + ModelContextWindowTokens / HasModelContextWindowTokens│   ║
║  │                                                          │   ║
║  │  ┌────────────────────────────────────────────────────┐  │   ║
║  │  │  Layer 1 — wesm/agentsview (upstream base)         │  │   ║
║  │  │                                                    │  │   ║
║  │  │  Session indexing + SQLite storage (agentsview DB) │  │   ║
║  │  │  Parser framework (internal/parser/types.go)       │  │   ║
║  │  │  All registered agents (Claude, Codex, Gemini …)   │  │   ║
║  │  │  Go HTTP server + Svelte 5 frontend                │  │   ║
║  │  │  Signals engine (internal/signals/)                │  │   ║
║  │  │  sync engine (internal/sync/)                      │  │   ║
║  │  │  GitHub Actions release workflow                   │  │   ║
║  │  │  Tauri desktop wrapper                             │  │   ║
║  │  └────────────────────────────────────────────────────┘  │   ║
║  └──────────────────────────────────────────────────────────┘   ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## Layer 1 — wesm/agentsview

**Role:** Upstream foundation. We never modify Layer 1 files unless Layer 2 or
Layer 3 features require it. When upstream releases, we pull it in via the sync
workflow (see below).

**Key files owned by Layer 1 (take theirs on conflict):**

| File / Package | Rule |
|---|---|
| `internal/parser/types.go` | Take upstream — new agents live here |
| `internal/parser/codex*.go` | Take upstream |
| `internal/sync/engine.go` | Take upstream |
| `internal/postgres/push.go` | Take upstream |
| `internal/db/db.go` `dataVersion` | Take upstream if higher |
| `.github/workflows/release.yml` | Adapt to fork (rename binary/repo) |
| `Dockerfile`, `docker-compose*.yml` | Take upstream |

---

## Layer 2 — latentsignal-org/periscope

**Role:** Periscope product features. This is the raison d'être of the fork.
These features must be preserved in every upstream sync, even if upstream
removes them or the code they depend on is marked deprecated upstream.

**Invariant:** If a Periscope feature uses deprecated upstream code, that
deprecated code is NOT removed. Preserve it alongside the upstream replacement.

### Periscope-specific features (always preserve)

| Feature | Location | Preserve rule |
|---|---|---|
| **ContextPage** | `frontend/src/lib/components/context/ContextPage.svelte` | Always keep; keep `sessionTab() === "context"` branch in App.svelte |
| **ActivityMinimap** | wired via `ui.activityMinimapOpen` in App.svelte | Keep our block above transcript |
| **Summarizer worker** | `internal/summarize/` | Keep; needs `ANTHROPIC_API_KEY` |
| **LLM client** | `internal/llm/` | Keep; direct Anthropic HTTPS calls |
| **Guidance client** | `guidanceClient`, `guidanceModel`, `guidanceCache` in server.go | Keep; Phase B banner text |
| **JetBrains plugin scaffold** | `jetbrains-plugin/` | Keep; we extend it in Layer 3 |
| **API routes** | `/api/v1/sessions/{id}/context`, `/context/timeline`, `POST /summarize` | Keep alongside upstream new routes |
| **Dev proxy** | `frontend/vite.config.ts` `applyDevProxyHeaders` / `getDevProxyTarget` | Keep ours; upstream uses simpler proxy |
| **Context types export** | `frontend/src/lib/api/types/index.ts` → `./context.js` | Keep alongside upstream new exports |
| **ModelContextWindowTokens** | `IncrementalInfo` struct in `internal/db/sessions.go` | Keep both our fields AND upstream's new fields (union) |
| **README.md / CLAUDE.md** | repo root | Always keep ours (Periscope branding) |

### Conflict resolution patterns (2026-05-10 merge, 13 conflicts)

| Conflict site | Resolution |
|---|---|
| `App.svelte` line ~469 | Keep our ActivityMinimap + ContextPage/MessageList tab block; add upstream's `SessionVitals` snippet |
| `sessions.go` `IncrementalInfo` | Union — keep `ModelContextWindowTokens`/`HasModelContextWindowTokens` AND add upstream's `FileMtime`/`FileInode`/`FileDevice`/`FirstMessage` |
| `server.go` imports | Keep `llm`+`summarize` AND add upstream's `service` |
| `server.go` routes | Keep our `/context`/`/context/timeline`/`/summarize` AND add upstream's `/timing` |
| `db.go` `dataVersion` | Take upstream's if higher (took 27 over our 14) |
| `types/index.ts` | Export both `./context.js` AND upstream's new exports |
| `frontend/vite.config.ts` | Keep ours (take HEAD) |
| `README.md`, `CLAUDE.md` | Keep ours (take HEAD) |
| `internal/parser/types.go` | Take upstream (new agents) |

---

## Layer 3 — diazMelgarejo/periscope (this repo)

**Role:** Fork identity, build system, release pipeline, and JetBrains plugin
production-readiness. These are our additions on top of Layers 1+2.

### What we add

| Addition | Purpose |
|---|---|
| Module path `github.com/latentsignal-org/periscope` | Fork identity; matches plugin.xml `org.latentsignal.periscope` |
| Binary name `periscope` | Renamed from `agentsview` throughout |
| Version `v0.29.2-periscope.2` | Versioning scheme (see below) |
| `scripts/sync-upstream.sh` | Repeatable upstream merge with interactive conflict resolution |
| `scripts/install.sh` (updated) | Downloads from diazMelgarejo releases; falls back to `make build` |
| GitHub Actions `release.yml` (updated) | Builds `periscope-{os}-{arch}` binaries on `v*` tags |
| `PeriscopeProcessManager.kt` | Auto-start/stop periscope binary from JetBrains IDE |
| `main.go` `Version` var | Injected at build time by Makefile |

---

## Branch Strategy

| Branch | Purpose | Update rule |
|---|---|---|
| `agentsview` | Mirrors `wesm/agentsview` main exactly | `git fetch upstream && git push origin agentsview --force` after fetching |
| `main` | Periscope features on top of fork point (47ca74c6) | Manual feature work only |
| `merged` | **Shipping branch** — upstream merged into Periscope, preserving all Layer 2+3 features | Run `scripts/sync-upstream.sh` on each upstream release |

---

## Versioning Scheme

```
v0.(upstream_minor + 1).2-periscope.2
```

| upstream release | our release |
|---|---|
| v0.28.0 | v0.29.2-periscope.2 |
| v0.29.0 | v0.30.2-periscope.2 |
| v0.30.0 | v0.31.2-periscope.2 |

- **Minor:** always one above upstream's minor — makes the base version readable
- **Patch:** `2` — Periscope generation 2 (increment if we ship a patch on a frozen upstream base)
- **Pre-release:** `-periscope.2` — fork identity; generation 2

To tag a release:
```bash
git tag v0.29.2-periscope.2
git push origin v0.29.2-periscope.2
```
GitHub Actions picks up the `v*` tag and builds all platform binaries.

---

## Repeatable Sync Workflow

Run `scripts/sync-upstream.sh` whenever upstream releases. The script:

1. `git fetch upstream`
2. Force-updates `agentsview` branch → `upstream/main`
3. Switches to `merged`, runs `git merge upstream/main --no-commit --no-ff`
4. For each conflict file, checks it against the **known-patterns table**:
   - Known pattern → auto-resolved silently (logged)
   - Unknown file → **STOP, show diff, ask you, wait for your decision**
5. After all conflicts resolved (auto + manual), commits and pushes

**Interactive mode:** On unknown conflicts the script shows:
```
CONFLICT: internal/server/analytics.go (unknown pattern)
--- upstream/main
+++ HEAD
[diff output]
Options: [k]eep ours / [t]ake theirs / [b]oth / [e]dit manually / [q]uit
```

You choose. Your choice is recorded in the commit message for the next merge.

### After a sync: update versioning

```bash
# Update Version in main.go
OLD_VERSION="v0.X.2-periscope.2"
NEW_VERSION="v0.(X+1).2-periscope.2"
sed -i '' "s/$OLD_VERSION/$NEW_VERSION/" cmd/periscope/main.go
git add cmd/periscope/main.go
git commit -m "chore: bump version to $NEW_VERSION after upstream v0.X.0 sync"
```

---

## Local Build

```bash
# Prerequisites: Go 1.26+, Node 20+, CGO dependencies (libsqlite3)
make frontend          # builds Svelte 5 → frontend/dist/
make build             # CGO_ENABLED=1 go build -tags fts5 -o periscope ./cmd/periscope
make install           # copies periscope to ~/.local/bin/
```

Or one shot:
```bash
make install
```

The binary serves the embedded frontend and SQLite DB at `http://localhost:8080` by default.

---

## Release Pipeline

Triggered by pushing a `v*` tag to `diazMelgarejo/periscope`:

```
git tag v0.29.2-periscope.2 && git push origin v0.29.2-periscope.2
```

GitHub Actions (`release.yml`) builds:

| Target | Output |
|---|---|
| linux/amd64 | `periscope-linux-amd64` |
| linux/arm64 | `periscope-linux-arm64` |
| darwin/arm64 | `periscope-darwin-arm64` |
| windows/amd64 | `periscope-windows-amd64.exe` |

JetBrains plugin (`gradlew buildPlugin`) → `periscope-jetbrains-{version}.zip` — attached to same GitHub release.

---

## Install Script

```bash
curl -fsSL https://raw.githubusercontent.com/diazMelgarejo/periscope/merged/scripts/install.sh | bash
```

Script behaviour:
1. Detect OS + arch
2. Try `https://github.com/diazMelgarejo/periscope/releases/latest/download/periscope-{os}-{arch}`
3. If release not found → clone `merged` branch → `make build` from source
4. Install to `~/.local/bin/periscope`

---

## JetBrains Plugin Lifecycle

`PeriscopeProcessManager.kt` manages the periscope binary:

**On project open:**
1. Locate binary: `$PERISCOPE_BIN` env → `~/.local/bin/periscope` → bundled in plugin resources
2. Check if port 8080 is already in use (another instance running)
3. If not: `ProcessBuilder("periscope", "--port", "8080", "--data-dir", projectDataDir)`
4. Poll `localhost:8080` for HTTP 200 (max 10s, 500ms intervals)
5. Load `JBCefBrowser("http://localhost:8080/")`

**On project/IDE close:**
1. SIGTERM to managed process
2. Wait 3 seconds
3. SIGKILL if still alive

**Binary not found:** Show a notification with install instructions and a link to the install script.

---

## Existing Plans to Follow

All plans in `docs/` are active. Implement in this order:

| Priority | Document | Covers |
|---|---|---|
| 1 | [`periscope-v1-plan.md`](./periscope-v1-plan.md) | Context Visualizer V1 (FR1/FR2/FR3/FR8/FR9) — **must ship first** |
| 2 | [`periscope-v2-llm-plan.md`](./periscope-v2-llm-plan.md) | LLM guidance layer (Phase A→D) — requires `ANTHROPIC_API_KEY` |
| 3 | [`context-session-visualizer-mvp-plan.md`](./context-session-visualizer-mvp-plan.md) | MVP scope definition — reference for what NOT to include in V1 |
| 4 | [`desktop-release-setup.md`](./desktop-release-setup.md) | macOS notarization + Tauri signing for desktop release |
| ref | [`periscope-spec.md`](./periscope-spec.md) | Full product spec — source of truth for all FRs |
| ref | [`v1-ui-spec.md`](./v1-ui-spec.md) | V1 UI design — Option C timeline is the chosen layout |

---

## What Is Never Removed

Even if upstream removes or deprecates the following, we keep them:

1. Any code that `internal/summarize/` or `internal/llm/` imports
2. `ModelContextWindowTokens` and `HasModelContextWindowTokens` fields on `IncrementalInfo`
3. `ContextPage.svelte` and all its imports
4. `ActivityMinimap` and `ui.activityMinimapOpen` wiring
5. The `/context`, `/context/timeline`, and `/summarize` API routes
6. `applyDevProxyHeaders` / `getDevProxyTarget` in `vite.config.ts`
7. `export type * from "./context.js"` in `types/index.ts`
8. Periscope README.md and CLAUDE.md branding

**Rule:** If a Periscope feature depends on code upstream marks deprecated, add
a comment `// periscope: keep — required by internal/summarize` and leave it.
The sync script's known-patterns table will auto-preserve it.

---

## Repeatable Checklist: After Every Upstream Sync

- [ ] `scripts/sync-upstream.sh` ran cleanly (or conflicts resolved interactively)
- [ ] All Periscope-specific features verified present (run `grep -r "ContextPage\|ActivityMinimap\|guidanceClient" .`)
- [ ] `go build -tags fts5 ./...` passes
- [ ] `make frontend && make build` produces working binary
- [ ] `dataVersion` in `internal/db/db.go` updated to upstream's value if higher
- [ ] Version bumped in `cmd/periscope/main.go` per versioning scheme
- [ ] Commit message format: `merge: upstream wesm/agentsview vX.Y.Z into periscope (merged branch)`
- [ ] This `docs/ARCHITECTURE.md` updated if any new conflict pattern was discovered

---

## Repeatable Checklist: Cutting a Release

- [ ] All tests pass: `go test -tags fts5 ./...`
- [ ] Frontend build clean: `make frontend`
- [ ] Binary builds on local Mac: `make build`
- [ ] Version string correct in `cmd/periscope/main.go`
- [ ] Tag pushed: `git tag vX.Y.Z-periscope.2 && git push origin vX.Y.Z-periscope.2`
- [ ] GitHub Actions CI green (all 4 platform builds succeed)
- [ ] JetBrains plugin built: `cd jetbrains-plugin && ./gradlew buildPlugin`
- [ ] Plugin zip attached to GitHub release manually (or via CI)
- [ ] Install script tested on clean Mac: `curl ... | bash`

---

## Related documents

| Document | Role |
| --- | --- |
| [`periscope-upstream-sync-blueprint.md`](guides/periscope-upstream-sync-blueprint.md) | Canonical sync policy |
| [`periscope-modernization-status.md`](guides/periscope-modernization-status.md) | Current modernization snapshot |
| [`agentsview-to-periscope-rename-catalogue.md`](guides/agentsview-to-periscope-rename-catalogue.md) | Rename decision tree |
| [`superpowers/specs/2026-05-10-periscope-build-design.md`](https://github.com/diazMelgarejo/periscope/blob/merged/docs/superpowers/specs/2026-05-10-periscope-build-design.md) | Historical build design (May 2026) |
| [`superpowers/plans/2026-05-10-periscope-build-system.md`](https://github.com/diazMelgarejo/periscope/blob/merged/docs/superpowers/plans/2026-05-10-periscope-build-system.md) | Historical implementation plan |

