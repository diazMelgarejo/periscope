# Periscope Build System — Implementation Progress

> **Resumable:** If this session ends, start a new session pointing at this file.
> Branch: `merged` | Worktree: `/tmp/periscope-work/periscope`
> Plan: `docs/superpowers/plans/2026-05-10-periscope-build-system.md`
> Spec: `docs/superpowers/specs/2026-05-10-periscope-build-design.md`
> Architecture: `docs/ARCHITECTURE.md`

## Status

| # | Task | Status | Commit | Notes |
|---|---|---|---|---|
| 1 | Go Module Rename | 🔄 in progress | — | |
| 2 | Binary + Makefile Rename | ⏳ pending | — | |
| 3 | Version String in main.go | ⏳ pending | — | |
| 4 | Update install.sh | ⏳ pending | — | |
| 5 | Create sync-upstream.sh | ⏳ pending | — | |
| 6 | Update release.yml | ⏳ pending | — | |
| 7 | Create PeriscopeProcessManager.kt | ⏳ pending | — | |
| 8 | Wire MyToolWindowFactory + MyProjectActivity | ⏳ pending | — | |
| 9 | Build verification + tag v0.29.2-periscope.2 | ⏳ pending | — | |
| 10 | E2E install script test | ⏳ pending | — | |

## Model Strategy

| Task | Model | Reason |
|---|---|---|
| 1, 2, 3 | haiku | Mechanical sed/rename — no judgment needed |
| 4, 5, 6 | sonnet | Script/YAML writing — spec fully defines content |
| 7, 8 | sonnet | Kotlin/IntelliJ Platform — needs API knowledge |
| 9, 10 | inline | CI trigger + local Mac test — not delegatable |
| Reviews | haiku + LM Studio (192.168.254.104:1234) | Spec compliance checks |

## Local Model Resources

- **Ollama (Mac localhost:11434):** Available for mechanical review passes
- **LM Studio (Windows 192.168.254.104:1234):** Available via OpenClaw for parallel review

## How to Resume

```bash
cd /tmp/periscope-work/periscope
git checkout merged
git log --oneline -10
# Find the last completed task commit, then continue from the next task
# in docs/superpowers/plans/2026-05-10-periscope-build-system.md
```

## Target Release

`v0.29.2-periscope.2` on `diazMelgarejo/periscope` — first release of the fork.
