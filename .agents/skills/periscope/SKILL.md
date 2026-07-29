```markdown
# periscope Development Patterns

> Auto-generated skill from repository analysis

## Overview

This skill teaches you the core development patterns, coding conventions, and workflows used in the `periscope` Go codebase. You'll learn how to add new database features, implement new parsers/providers, and develop features with proper tests and documentation. The guide covers file organization, code style, and step-by-step instructions for common contribution workflows.

---

## Coding Conventions

**File Naming**
- Use `snake_case` for file names.
  - Example: `session_parser.go`, `db_utils.go`

**Imports**
- Use absolute import paths.
  - Example:
    ```go
    import "github.com/yourorg/periscope/internal/db"
    ```

**Exports**
- Use named exports for functions, types, and variables.
  - Example:
    ```go
    // Exported function
    func NewSessionParser() *SessionParser {
        // ...
    }
    ```

**Commit Messages**
- Prefix with `fix:` or `feat:`
- Keep messages concise (~54 characters on average)
  - Example: `feat: add support for new agent provider`

---

## Workflows

### Add or Update Database Feature
**Trigger:** When adding a new database-backed feature or modifying database structure/logic  
**Command:** `/new-table`

1. Edit or add SQL schema files (e.g., `internal/db/schema.sql`).
2. Update Go code for database access and logic (e.g., `internal/db/*.go`).
3. Add or update trigger DDL and migration logic in Go (e.g., `internal/db/db.go`).
4. Write or update tests for new/changed database logic (e.g., `internal/db/*_test.go`, `cmd/agentsview/*_test.go`).
5. Update or add documentation/specs if the feature is significant (e.g., `docs/superpowers/specs/...`).

**Example:**
```sql
-- internal/db/schema.sql
ALTER TABLE sessions ADD COLUMN agent_version TEXT;
```
```go
// internal/db/session.go
func (db *DB) AddAgentVersion(sessionID int, version string) error {
    // implementation
}
```
```go
// internal/db/session_test.go
func TestAddAgentVersion(t *testing.T) {
    // test logic
}
```

---

### Add New Parser or Provider
**Trigger:** When supporting a new agent or data format  
**Command:** `/add-parser`

1. Add new parser/provider Go files (e.g., `internal/parser/<provider>_provider.go`, `internal/parser/<provider>.go`).
2. Update provider registry or discovery (e.g., `internal/parser/provider.go`).
3. Add or update test data and test cases (e.g., `internal/parser/testdata/<provider>/*.json`, `internal/parser/<provider>_test.go`).
4. Integrate with sync engine if needed (e.g., `internal/sync/engine.go`).
5. Update documentation and format sources (e.g., `docs/internal/session-format-sources.md`, `docs/configuration.md`).
6. Update frontend agent lists if surfaced (e.g., `frontend/src/lib/utils/agents.ts`).

**Example:**
```go
// internal/parser/myagent_provider.go
type MyAgentProvider struct { /* ... */ }
func (p *MyAgentProvider) Parse(data []byte) (*Session, error) { /* ... */ }
```
```go
// internal/parser/provider.go
func init() {
    RegisterProvider("myagent", &MyAgentProvider{})
}
```
```json
// internal/parser/testdata/myagent/sample.json
{ "session_id": 123, "agent": "myagent", ... }
```

---

### Feature Development with Tests and Docs
**Trigger:** When developing a new feature or major enhancement  
**Command:** `/feature`

1. Implement feature in Go (e.g., `internal/<area>/*.go`).
2. Write or update tests (e.g., `internal/<area>/*_test.go`, `cmd/agentsview/*_test.go`).
3. Update or add documentation/specs (e.g., `docs/superpowers/specs/*.md`, `docs/configuration.md`).
4. Update frontend if feature is user-facing (e.g., `frontend/src/lib/utils/agents.ts`).

**Example:**
```go
// internal/feature/awesome.go
func EnableAwesomeFeature() error {
    // feature logic
}
```
```go
// internal/feature/awesome_test.go
func TestEnableAwesomeFeature(t *testing.T) {
    // test logic
}
```
```markdown
<!-- docs/superpowers/specs/awesome_feature.md -->
# Awesome Feature Spec
...
```

---

## Testing Patterns

- Test files use the pattern `*_test.go`.
- Tests are written using Go's standard `testing` package.
- Test data may be stored in `testdata` directories, often as JSON files for parsers.
- Example test file:
    ```go
    // internal/parser/myagent_test.go
    func TestMyAgentParser(t *testing.T) {
        // Arrange
        data, _ := ioutil.ReadFile("testdata/myagent/sample.json")
        // Act
        session, err := MyAgentProvider{}.Parse(data)
        // Assert
        if err != nil { t.Fatal(err) }
        // Additional assertions...
    }
    ```

---

## Commands

| Command      | Purpose                                                        |
|--------------|----------------------------------------------------------------|
| /new-table   | Add or update a database-backed feature or schema              |
| /add-parser  | Add support for a new agent/provider/parser                    |
| /feature     | Implement a new feature or significant enhancement with tests  |
```
