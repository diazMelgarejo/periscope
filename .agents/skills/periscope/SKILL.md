```markdown
# periscope Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches you the core development patterns and conventions used in the `periscope` TypeScript codebase. You'll learn how to name files, structure imports/exports, write commits, and organize tests. This guide also provides suggested commands for common workflows, ensuring consistency and efficiency in your contributions.

## Coding Conventions

### File Naming
- Use **kebab-case** for all file names.
  - Example:  
    ```
    user-profile.ts
    data-fetcher.test.ts
    ```

### Import Style
- Use **relative imports** for module references.
  - Example:
    ```typescript
    import { fetchData } from './data-fetcher';
    ```

### Export Style
- Use **named exports** only.
  - Example:
    ```typescript
    // In user-profile.ts
    export function getUserProfile(id: string) { ... }
    ```

### Commit Messages
- Follow **conventional commit** format.
- Use the `chore` prefix for all commits.
- Keep commit messages concise (average ~59 characters).
  - Example:
    ```
    chore: update dependencies to latest versions
    ```

## Workflows

### Code Contribution
**Trigger:** When adding or updating code  
**Command:** `/contribute`

1. Create or update files using kebab-case naming.
2. Use relative imports and named exports.
3. Write clear, conventional commit messages with the `chore` prefix.
4. If applicable, add or update corresponding test files (`*.test.ts`).

### Testing
**Trigger:** When verifying code correctness  
**Command:** `/test`

1. Locate or create a test file matching `*.test.*` pattern.
2. Write or update test cases as needed.
3. Run your test suite using the project's test runner (framework unknown; check project scripts or documentation).
4. Ensure all tests pass before committing.

## Testing Patterns

- Test files follow the `*.test.*` naming convention (e.g., `user-profile.test.ts`).
- The specific testing framework is not detected; check existing test files for structure or consult project documentation.
- Place tests close to the code they verify for clarity and maintainability.

## Commands
| Command      | Purpose                                    |
|--------------|--------------------------------------------|
| /contribute  | Guide for contributing code changes        |
| /test        | Steps for writing and running tests        |
```
