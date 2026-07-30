```markdown
# periscope Development Patterns

> Auto-generated skill from repository analysis

## Overview

This skill teaches you how to contribute effectively to the `periscope` codebase, a Go project focused on agent, data source, and artifact management with integrated backend and frontend components. You'll learn the repository's coding conventions, step-by-step workflows for adding features, evolving the database, managing artifact pipelines, and more. The guide covers both backend (Go) and frontend (TypeScript/Svelte) practices, including testing and documentation standards.

---

## Coding Conventions

**File Naming**
- Use `snake_case` for Go files:  
  Example: `agent_provider.go`, `export_checkpoint.go`
- Test files: `<name>_test.go` for Go, `<name>.test.ts` for TypeScript

**Imports**
- Use relative imports in Go:
  ```go
  import "../parser"
  ```
- For TypeScript, use relative paths:
  ```typescript
  import { getAgent } from './agents';
  ```

**Exports**
- Use named exports in both Go and TypeScript:
  ```go
  func NewProvider() *Provider { ... }
  ```
  ```typescript
  export function getAgent() { ... }
  ```

**Commit Messages**
- Follow [Conventional Commits](https://www.conventionalcommits.org/):
  - Prefixes: `fix:`, `feat:`, `test:`
  - Example: `feat(parser): add support for new agent format`

---

## Workflows

### Add New Parser or Provider
**Trigger:** When you want to support a new chat agent or data source format  
**Command:** `/add-provider`

1. Implement parser/provider logic in `internal/parser` (e.g., `<agent>_provider.go`, `<agent>.go`)
2. Add or update types in `internal/parser/types.go`
3. Register the provider in `internal/parser/provider.go` and/or `provider_migration.go`
4. Add test fixtures in `internal/parser/testdata/<agent>/*` and tests in `<agent>_test.go`
5. Integrate with the sync engine (`internal/sync/engine.go`, `engine_test.go`, `integration_test.go`)
6. Update documentation:  
   - `docs/internal/session-format-sources.md`
   - `docs/configuration.md`
7. If needed, update frontend agent utilities/tests:  
   - `frontend/src/lib/utils/agents.ts`
   - `frontend/src/lib/utils/agents.test.ts`

**Example:**  
```go
// internal/parser/myagent_provider.go
type MyAgentProvider struct { ... }

func (p *MyAgentProvider) Parse(...) { ... }
```

---

### Add or Evolve Database Table and Ledger
**Trigger:** When you need to persist new data types or add a new ledger/queue  
**Command:** `/new-table`

1. Add or modify SQL schema in `internal/db/schema.sql`
2. Implement Go model and accessors in `internal/db/<table>.go`
3. Add or update triggers/migrations in `internal/db/db.go`
4. Write or update tests in `internal/db/<table>_test.go` and `db_test.go`
5. Update related logic in feature code (e.g., `internal/artifact/*`, `internal/parser/*`)
6. Update documentation/specs if needed

**Example:**  
```sql
-- internal/db/schema.sql
CREATE TABLE my_table (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL
);
```
```go
// internal/db/my_table.go
type MyTable struct {
  ID   int
  Name string
}
```

---

### Feature Development with End-to-End Tests and Docs
**Trigger:** When adding a user-facing feature or major capability  
**Command:** `/new-feature`

1. Implement backend logic in `internal/<feature>/*.go`
2. Integrate with CLI or daemon (`cmd/agentsview/*.go`)
3. Update or add API endpoints (`internal/server/*.go`)
4. Update or add frontend components and stores:  
   - `frontend/src/lib/components/<feature>/*.svelte`
   - `frontend/src/lib/stores/<feature>.ts`
   - `frontend/src/lib/utils/<feature>.ts`
5. Write or update backend and frontend tests
6. Update documentation:  
   - `docs/<feature>.md`
   - `README.md`
7. Add or update `testdata/golden/*` if output shape changes

**Example:**  
```go
// internal/myfeature/handler.go
func HandleFeature(...) { ... }
```
```typescript
// frontend/src/lib/components/myfeature/MyFeature.svelte
<script lang="ts">
  export let data: MyFeatureType;
</script>
```

---

### Add or Evolve Artifact Export/Import Pipeline
**Trigger:** When improving artifact synchronization, export, or import reliability  
**Command:** `/artifact-pipeline`

1. Implement or update export/import logic:  
   - `internal/artifact/export.go`
   - `internal/artifact/import.go`
2. Add or update checkpoint/queue management:  
   - `internal/artifact/export_checkpoint.go`
   - `internal/artifact/import_checkpoint.go`
3. Add or update DB accessors and triggers:  
   - `internal/db/artifact_*.go`
   - `internal/db/db.go`
   - `internal/db/schema.sql`
4. Write or update tests for artifact logic and DB:  
   - `internal/artifact/*_test.go`
   - `internal/db/artifact_*_test.go`
5. Update documentation/specs if needed

---

### Add or Evolve Pricing Refresh and Usage Metrics
**Trigger:** When supporting new pricing models or improving usage analytics  
**Command:** `/pricing-refresh`

1. Implement/modify pricing refresh logic:  
   - `internal/pricingrefresh/refresh.go`
   - `cmd/agentsview/pricing_schedule.go`
2. Update pricing models and provenance:  
   - `internal/db/pricing.go`
   - `internal/export/pricing.go`
   - `internal/parser/types.go`
3. Update usage analytics logic:  
   - `internal/db/usage.go`
   - `internal/duckdb/analytics_usage.go`
   - `internal/postgres/usage.go`
4. Update or add frontend usage pages and components:  
   - `frontend/src/lib/components/usage/*`
   - `frontend/src/lib/stores/usage.svelte.ts`
   - `frontend/src/lib/components/usage/usageMode.ts`
5. Write or update backend and frontend tests
6. Update documentation:  
   - `docs/token-usage.md`
   - `docs/activity.md`

---

## Testing Patterns

- **Backend (Go):**
  - Test files are named `<name>_test.go`
  - Use Go's standard testing package:
    ```go
    func TestMyFeature(t *testing.T) {
      // test logic
    }
    ```
- **Frontend (TypeScript):**
  - Test files use `.test.ts` suffix
  - Use Jest for unit and integration tests:
    ```typescript
    test('should return correct agent', () => {
      expect(getAgent('foo')).toBe('bar');
    });
    ```
- **Test Data:**  
  - Place fixtures in `internal/parser/testdata/<agent>/*`
  - Use `testdata/golden/*` for output shape validation

---

## Commands

| Command           | Purpose                                                         |
|-------------------|-----------------------------------------------------------------|
| /add-provider     | Add support for a new agent, data source, or provider           |
| /new-table        | Add or evolve a database table and ledger                       |
| /new-feature      | Implement a new feature or major enhancement                    |
| /artifact-pipeline| Add or evolve the artifact export/import pipeline               |
| /pricing-refresh  | Add or update pricing refresh logic and usage metrics           |
```
