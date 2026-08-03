```markdown
# periscope Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches you the core development patterns used in the `periscope` Go codebase. You'll learn the project's coding conventions, commit message styles, file organization, and how to write and run tests. This guide is ideal for contributors aiming for consistency and maintainability in their work.

## Coding Conventions

### File Naming
- Use **snake_case** for all file names.
  - Example: `user_service.go`, `data_parser.go`

### Import Style
- Use **relative imports** within the module.
  - Example:
    ```go
    import (
        "fmt"
        "../utils"
    )
    ```

### Export Style
- Use **named exports** for functions, types, and variables that should be accessible outside the package.
  - Example:
    ```go
    // Exported function
    func ProcessData(input string) string {
        // ...
    }
    ```

### Commit Messages
- Follow **conventional commit** style.
- Common prefixes: `revert`, `fix`, `docs`
- Example:
  ```
  fix: handle nil pointer in data_parser.go
  docs: update README with installation steps
  revert: fix: handle nil pointer in data_parser.go
  ```

## Workflows

### Commit Changes
**Trigger:** When committing any change to the repository  
**Command:** `/commit-changes`

1. Stage your changes: `git add .`
2. Write a commit message using the conventional commit style.
   - Example: `fix: correct typo in user_service.go`
3. Commit: `git commit -m "fix: correct typo in user_service.go"`
4. Push your changes: `git push`

### Add Documentation
**Trigger:** When updating or adding documentation  
**Command:** `/add-docs`

1. Edit or create documentation files (e.g., `README.md`).
2. Use clear, concise language and code examples where appropriate.
3. Commit with the `docs:` prefix.
   - Example: `git commit -m "docs: add usage example to README"`
4. Push your changes.

### Revert a Commit
**Trigger:** When you need to undo a previous commit  
**Command:** `/revert-commit`

1. Find the commit hash: `git log`
2. Revert the commit: `git revert <commit-hash>`
3. Commit with the `revert:` prefix.
   - Example: `git commit -m "revert: fix: correct typo in user_service.go"`
4. Push your changes.

## Testing Patterns

- Test files follow the pattern: `*.test.*`
  - Example: `user_service.test.go`
- The specific testing framework is not defined; use standard Go testing conventions unless otherwise specified.
- Example test file structure:
  ```go
  package user

  import "testing"

  func TestProcessData(t *testing.T) {
      result := ProcessData("input")
      if result != "expected" {
          t.Errorf("Expected %v, got %v", "expected", result)
      }
  }
  ```

## Commands
| Command           | Purpose                                        |
|-------------------|------------------------------------------------|
| /commit-changes   | Guide for committing code with conventions     |
| /add-docs         | Steps for updating or adding documentation     |
| /revert-commit    | Instructions for reverting a previous commit   |
```
