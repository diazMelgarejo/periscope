```markdown
# periscope Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches the core development patterns and conventions used in the `periscope` Go repository. You'll learn about file naming, import/export styles, commit message conventions, and how to structure and run tests. This guide is ideal for contributors looking to maintain consistency and quality in the codebase.

## Coding Conventions

### File Naming
- Use **snake_case** for all file names.
  - Example:  
    ```
    data_processor.go
    user_service.go
    ```

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
- Use **named exports** for functions, types, and variables.
  - Example:
    ```go
    // Exported function
    func ProcessData(input string) error {
        // ...
    }
    ```

### Commit Messages
- Follow **conventional commit** style.
- Use the `fix` prefix for bug fixes.
- Keep commit messages concise (average 61 characters).
  - Example:
    ```
    fix: handle nil pointer in data_processor.go
    ```

## Workflows

### Bug Fix Workflow
**Trigger:** When fixing a bug in the codebase  
**Command:** `/fix-bug`

1. Identify and reproduce the bug.
2. Create a new branch for the fix.
3. Apply the fix, following coding conventions.
4. Write or update relevant tests.
5. Commit changes using the `fix:` prefix.
6. Push the branch and open a pull request.

### Add Feature Workflow
**Trigger:** When adding a new feature  
**Command:** `/add-feature`

1. Create a new branch for the feature.
2. Implement the feature using snake_case file naming and relative imports.
3. Export new functions/types with named exports.
4. Write corresponding tests in `*.test.*` files.
5. Commit with a descriptive message (use a relevant conventional prefix).
6. Push the branch and open a pull request.

## Testing Patterns

- Test files follow the pattern: `*.test.*`
  - Example: `data_processor.test.go`
- Testing framework is not explicitly defined; use Go's standard testing tools unless otherwise specified.
- Place tests alongside the code they test, using the same naming conventions.

  Example test file:
  ```go
  // data_processor.test.go
  package periscope

  import "testing"

  func TestProcessData(t *testing.T) {
      // test logic here
  }
  ```

## Commands
| Command      | Purpose                                 |
|--------------|-----------------------------------------|
| /fix-bug     | Start the bug fix workflow              |
| /add-feature | Start the add feature workflow          |
```
