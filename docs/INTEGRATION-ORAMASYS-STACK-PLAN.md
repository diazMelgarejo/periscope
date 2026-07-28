# Periscope (AgentsView) — full-feature integration plan for orchestration stack

> **Date:** 2026-07-28  
> **Branch:** `merged` @ `origin/merged` (build target — never merge into `main`)  
> **Repo:** `oramasys/tools/periscope` (v2 workspace)  
> **Canonical design:** orama-system `docs/plans/2026-05-24-periscope-l4-integration-plan.md` (2026-07-28 revalidation)  
> **Prior research:** `OpenClaw/references/2026-07-28-periscope-agentsview-l4-integration-synthesis.md`

## Sync status (2026-07-28)

```bash
cd "$(git rev-parse --show-toplevel)/tools/periscope"
git fetch origin merged
git checkout merged
git reset --hard origin/merged   # local had diverged; remote is truth
```

| Ref | SHA | Notes |
|-----|-----|-------|
| `origin/merged` (HEAD) | `44593b77` | Desktop sidecar `periscope` stem fix (#14) |
| `origin/agentsview` | `6c3317ad` | Upstream mirror tip |
| `origin/main` | `852b8e38` | latentsignal mirror only |

**Binary:** `cmd/periscope/`. Version: `v0.29.2-periscope.2`.

---

## Stack placement

```text
L1  AlphaClaw / gateways     transport
L2  Perpetua-Tools           orchestrator, envelopes, `.state`
L3  orama-system / oramasys  methodology + graph (stateless orchestration API)
L4  Periscope (this repo)    read-only observability — full AgentsView feature set
```

| Generation | Repos | L4 policy |
|------------|-------|-----------|
| **v1-perpetua-orama** | orama-system, Perpetua-Tools, OpenClaw/Hermes fleet | **Optional** — `PERISCOPE_AUTOSTART=0` default |
| **v2-oramasys** | perpetua-core, oramasys, `tools/periscope` | **Obligatory** — start scripts + CI consume L4 |

**Invariant:** Periscope never writes to L1–L3. PT normalizes to OpenClaw-compatible JSONL; Periscope uses `internal/parser/openclaw.go`.

---

## Integration principle (2026-07-28 revalidation)

**Do not** add stack-specific Periscope parsers or `/api/v1/openclaw/*` routes for v1.

```text
PT supervisor terminal job ──> periscope_adapter.py (opt-in)
OpenClaw agent sessions ──────> openclaw_dirs[] (absolute paths, both roots)
                                    ▼
              sync + SQLite + REST + Svelte UI + full CLI
```

```toml
# ~/.periscope/config.toml — paths must be absolute; ~ not expanded
openclaw_dirs = [
  "<absolute>/.openclaw/agents",
  "<absolute>/<supervisor-state>/periscope/agents",
]
```

Unset `OPENCLAW_DIR` when using `openclaw_dirs`. Reserve IDs: `pt-supervisor`, `alphaclaw-routing`.

---

## AgentsView feature → orchestration matrix

Integrate by wiring **L2/L3 consumers** to existing Periscope APIs — not new fork features.

### Core runtime

| Feature | CLI / API | v1 optional | v2 obligatory | Hook |
|---------|-----------|-------------|---------------|------|
| Sync + watcher | `sync`, `POST /api/v1/sync` | Manual | start scripts | After orchestration runs |
| SQLite + FTS5 | local DB | Mac | All nodes | L4 corpus |
| Daemon / serve | `periscope serve` | Opt-in | Default hub | `:8080` health |
| SSE live | `/sessions/{id}/watch`, `/api/v1/events` | Debug runs | Live dashboard | Pipeline monitor |
| Desktop Tauri | sidecar `periscope` | Win operators | Fleet | Fixed on merged (#14) |

### Session intelligence

| Feature | API | v1 | v2 |
|---------|-----|----|----|
| List / detail / messages | `/api/v1/sessions*` | ✓ | ✓ |
| Context + timeline | `.../context`, `.../context/timeline` | ✓ | Budget gates |
| Tool calls, activity, timing | sub-routes | ✓ | SLA metrics |
| Children (subagents) | `.../children` | ✓ | Delegation graph |
| Summarize | `POST .../summarize` | Manual | Scheduled digests |
| Guidance / signals | insight + `analytics/signals` | Optional | Policy alerts |
| Health / watch CLI | `health`, `session watch` | ✓ | CI smoke |

### Search & analytics

| Feature | API / CLI | v2 emphasis |
|---------|-----------|-------------|
| FTS search | `GET /api/v1/search` | Hub recall |
| Semantic search | CLI `--semantic` | gbrain complement |
| Analytics suite | `/api/v1/analytics/*` | Fleet pulse |
| Stats JSON | `periscope stats --format json` | CI gate (`schema_version: 1`) |
| Usage APIs | `/api/v1/usage/summary`, top-sessions | Budget enforcement |
| Insights | `/api/v1/insights*` | Weekly operator digests |

### Cost accounting

| Feature | CLI | Hook |
|---------|-----|------|
| `usage daily` / `statusline` | coord status, shell prompts |
| `token-use` / session usage API | Peak context before dispatch |
| LiteLLM + cache economics | All models (LM Studio + cloud) |

### Multi-machine (v2)

| Feature | CLI | Fleet |
|---------|-----|-------|
| `pg push --watch` | 3080/5080 → hub PG |
| `pg serve` | Team read-only dashboard |
| S3 session roots | Win push, Mac central reader |
| `sessions/upload` | Remote ingest |

### Built-in parsers (configure paths only)

OpenClaw, Hermes, Claude, Cursor, Codex, Gemini, Kimi, Grok, Forge, Piebald, … — see `internal/parser/`.

---

## Phased execution

### Phase 0 — `merged` hygiene (0.5 d)

1. `git reset --hard origin/merged`
2. `scripts/sync-upstream.sh` when upstream moves
3. `orama-system/scripts/periscope/install-cursor-rules.sh` on clone
4. `go build -o periscope ./cmd/periscope`
5. Desktop smoke (sidecar stem = `periscope`)

### Phase 1 — v1 optional (1 week)

**Perpetua-Tools:**

- `orchestrator/periscope_adapter.py` + tests (`PERISCOPE_EMITTER_ENABLED=1`, default off)
- Supervisor terminal-state hook
- Emit to `<state_dir>/periscope/agents/pt-supervisor/`

**orama-system:**

- L4 registry + `.env` template (`PERISCOPE_URL`, blank `PERISCOPE_TOKEN`)
- `PERISCOPE_AUTOSTART=0`

**Acceptance:** PT job visible in Periscope; `usage daily` includes fleet agents; no L4→L2 writes.

### Phase 2 — API consumers in L2 (1 week)

- `coord_pulse` → `usage statusline`, analytics activity
- Autoplan → `stats --format json`
- Pre-merge → `session usage` peak context

No Periscope code changes.

### Phase 3 — v2 obligatory (2 weeks)

- `PERISCOPE_AUTOSTART=1` in v2 start scripts
- `pg push --watch` per fleet node
- oramasys graph runs → same adapter contract
- CI gates on `stats` + `usage` JSON

### Phase 4 — Deferred

AlphaClaw raw parser, `/api/v1/openclaw/*`, gbrain bridge, lineage epic (45 vs 583 patches).

---

## Auth

- API: `auth_token` + `Authorization: Bearer` when `require_auth=true`
- Template: blank `PERISCOPE_TOKEN=` only in git
- `cursor_secret` = pagination signing, not API bearer

---

## Smoke tests

```bash
go test ./internal/parser/... -run OpenClaw -count=1
periscope serve &
curl -sS http://127.0.0.1:8080/api/v1/sessions | jq '.sessions | length'
periscope usage daily --json | jq '.days | length'
```

---

## Related

| Doc | Path |
|-----|------|
| orama revalidation plan | `orama-system/docs/plans/2026-05-24-periscope-l4-integration-plan.md` |
| PT adapter draft | `Perpetua-Tools/.agent/memory/working/PERISCOPE_L4_REVALIDATION_DRAFT_2026-07-28.md` |
| OpenClaw pointer | `OpenClaw/references/2026-07-28-periscope-oramasys-integration-plan.md` |
| Upstream sync | `tools/periscope/scripts/sync-upstream.sh` |
