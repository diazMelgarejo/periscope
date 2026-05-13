# Periscope Build System — Implementation Progress

> **Resumable:** If this session ends, start a new session pointing at this file.
> Branch: `merged` | Worktree: `/tmp/periscope-work/periscope`
> Plan: `docs/superpowers/plans/2026-05-10-periscope-build-system.md`
> Spec: `docs/superpowers/specs/2026-05-10-periscope-build-design.md`
> Architecture: `docs/ARCHITECTURE.md`

## Status

| # | Task | Status | Commit | Notes |
|---|---|---|---|---|
| 1 | Go Module Rename | ✅ done | `0158c93` | All ~163 .go files; GitHub API URL fixed |
| 2 | Binary + Makefile Rename | ✅ done | `b55dea5` | cmd/agentsview→cmd/periscope; 3 merge-residue fixes in sessions.go + db.go |
| 3 | Version String in main.go | ✅ done | `b55dea5` | v0.29.2-periscope.2; ldflags override for dev builds |
| 4 | Update install.sh | ✅ done | `5e27985` | REPO, BINARY_NAME, PERISCOPE_SKIP_CHECKSUM |
| 5 | Create sync-upstream.sh | ✅ done | `5e27985` | Auto-resolution + invariant verification |
| 6 | Update release.yml | ✅ done | `5e27985` | All binary/archive/artifact names updated |
| 7 | Create PeriscopeProcessManager.kt | ✅ done | `b0d404c` | start/stop/serverUrl; auto port-finding |
| 8 | Wire MyToolWindowFactory + MyProjectActivity | ✅ done | `b0d404c` | JBCefBrowser → serverUrl(); lifecycle wired |
| 9 | Build verification + tag v0.29.2-periscope.2 | ✅ done | `3cdcde5` | All 20 pkg tests pass; tag pushed; 5 platform binaries released |
| 10 | E2E install script test | ✅ done | — | darwin/arm64 install + checksum verified; binary reports correct version |

## Merge-Residue Fixes Applied (sessions.go / db.go)

These were silent merge bugs from the upstream merge — fixed in `b55dea5`:

1. **`upsertSessionSQL` VALUES placeholders**: 30 `?` → 32 (was missing model_context_window_tokens, has_model_context_window_tokens)
2. **`FindPruneCandidates` Scan**: added `&s.ModelContextWindowTokens`, `&s.HasModelContextWindowTokens`
3. **`ListSessionsModifiedBetween` Scan**: same fix
4. **`db.go` migrations**: added `ALTER TABLE` for both new periscope columns
5. **`automated_backfill_test.go`**: UpdateSessionIncremental calls 10→12 args

## Local Model Resources

- **Ollama (Mac localhost:11434):** Available for mechanical review passes
- **LM Studio (Windows 192.168.254.102:1234):** Available via OpenClaw for parallel review

## How to Resume

```bash
cd /tmp/periscope-work/periscope
git checkout merged
git log --oneline -10
# Find the last completed task commit, then continue from the next task
# in docs/superpowers/plans/2026-05-10-periscope-build-system.md
```

## Next Sync Upgrade Path

When upstream latentsignal-org/periscope releases a new version:
1. Run `./scripts/sync-upstream.sh --dry-run` to preview
2. Run `./scripts/sync-upstream.sh` to merge
3. Run `go test -tags fts5 ./...` and `make build`
4. Bump version: `v0.(upstream_minor+1).2-periscope.2` in cmd/periscope/main.go
5. Tag and push (include commit hash):
   ```bash
   COMMIT=$(git rev-parse --short HEAD)
   git tag -a "v0.XX.2-periscope.2-${COMMIT}" -m "Release v0.XX.2-periscope.2-${COMMIT}"
   git push origin "v0.XX.2-periscope.2-${COMMIT}"
   ```

## Release Tag Convention

Tags always embed the short commit hash of HEAD at release time:

```
v{semver}-{8-char-commit}   e.g.  v0.29.2-periscope.2-1895238
```

```bash
# How to tag a release (run from merged, after all commits are in):
COMMIT=$(git rev-parse --short HEAD)
VERSION="v0.29.2-periscope.2"   # bump as needed
git tag -a "${VERSION}-${COMMIT}" -m "Release ${VERSION}-${COMMIT}"
git push origin "${VERSION}-${COMMIT}"
```

## Target Release

`v0.29.2-periscope.2-1895238` on `diazMelgarejo/periscope` — first release of the fork.
