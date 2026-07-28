# periscope Development Patterns

> Synthesized from two ECC repository-analysis runs and verified against the
> repository's documented architecture and test layout.

## Overview

Periscope is a Go service and CLI backed by SQLite/FTS5, with a Svelte 5 and
TypeScript frontend embedded in the Go binary. It also includes a Tauri desktop
wrapper and optional PostgreSQL synchronization. Apply conventions within the
language and subsystem being changed rather than treating the repository as a
TypeScript-only project.

## Coding Conventions

### File and Symbol Naming

- Follow the surrounding subsystem's established naming.
- Frontend TypeScript files use **kebab-case** where applicable.
- TypeScript functions use **camelCase**, classes use **PascalCase**, and
  constants use **SCREAMING_SNAKE_CASE**.
- Go files, packages, and symbols follow idiomatic Go conventions.

### TypeScript Imports and Exports

- Prefer relative imports for project-local frontend modules.
- Prefer named exports where the surrounding module follows that pattern.

```typescript
import { fetchData } from "./data-fetcher";

export function getUserProfile(id: string) {
  return fetchData(id);
}
```

### Commit Messages

- Use Conventional Commits.
- Choose the prefix that describes the change; observed prefixes include
  `build`, `chore`, `docs`, `fix`, and scoped variants such as
  `fix(frontend)` and `fix(desktop)`.
- Keep the subject concise and include a scope when it adds useful context.

```text
build(deps): update frontend dependencies
fix(desktop): honor PERISCOPE_VERSION override
chore(git): sync attribution guard scripts
docs: align layer-2 synthesis analysis tip SHA
fix(frontend): remove stale ActivityMinimap and pass svelte-check
```

## Workflows

### Code Contribution

**Trigger:** When adding or updating code

**Guide:** `/contribute`

1. Read `AGENTS.md` and the conventions nearest to the files being changed.
2. Follow the naming, import, and export patterns of that subsystem.
3. Add or update tests for new features and bug fixes.
4. Run the targeted checks, then the broader affected suite.
5. Use a Conventional Commit prefix that matches the change.

### Dependency Update

**Trigger:** When updating a package or language ecosystem

**Guide:** `/update-dependencies`

**Instinct pair (keep both):**

- `periscope-workflow-dependency-update` — numbered workflow steps; trigger:
  "when doing dependency update".
- `periscope-instinct-dependency-update` — concise action summary; trigger:
  "When updating dependencies for a package or language ecosystem".

1. Update the relevant manifest, such as `frontend/package.json`,
   `desktop/package.json`, `desktop/src-tauri/Cargo.toml`, or `go.mod`.
2. Regenerate the corresponding lockfile or module metadata with the native
   package manager.
3. Review both manifest and generated dependency changes for unintended drift.
4. Run the checks for each affected subsystem.
5. Commit the manifest and lockfile together with a `build(deps)` subject.

### Integration Analysis Doc

**Trigger:** When updating layer-2 integrative synthesis verification or tip SHA

**Guide:** `/update-integration-analysis`

**Instinct:** `periscope-workflow-update-integration-analysis-doc` — numbered
workflow steps; trigger: "when doing update integration analysis doc".

1. Edit `docs/INTEGRATION-SYNTHESIS-LAYER2-ANALYSIS.md` for verification gates,
   branch references, or tip SHA alignment.
2. Use a `docs:` Conventional Commit subject that names the alignment work.
3. Keep the analysis consistent with the current `merged` integration line.

### Testing

**Trigger:** When verifying correctness

**Guide:** `/test`

1. Add tests in the location used by the affected subsystem.
2. Run the smallest relevant test target while iterating.
3. Run the broader affected suite before handoff.
4. For Go changes, run `go fmt ./...` and `go vet ./...`.

## Testing Patterns

- Go unit tests are colocated with packages as `*_test.go`; table-driven tests
  are preferred.
- Frontend unit tests are colocated as `*.test.ts` and run with Vitest.
- Browser journeys live in `frontend/e2e/` and run with Playwright.
- PostgreSQL integration tests use the `pgtest` build tag and a dedicated test
  database.
- Use `t.TempDir()` for isolated Go test data.

## Verified Commands

| Command | Purpose |
| --- | --- |
| `make test-short` | Run fast Go tests |
| `make test` | Run the full Go test suite |
| `cd frontend && npm test` | Run frontend Vitest tests |
| `make e2e` | Run Playwright end-to-end tests |
| `make vet` | Run Go static checks |
| `make lint` | Run configured Go linters |
