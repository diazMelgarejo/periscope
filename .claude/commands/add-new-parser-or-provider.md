---
name: add-new-parser-or-provider
description: Workflow command scaffold for add-new-parser-or-provider in periscope.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /add-new-parser-or-provider

Use this workflow when working on **add-new-parser-or-provider** in `periscope`.

## Goal

Adds support for a new agent/provider/parser, including implementation, integration, and test coverage.

## Common Files

- `internal/parser/*_provider.go`
- `internal/parser/*.go`
- `internal/parser/testdata/*/*.json`
- `internal/parser/*_test.go`
- `internal/parser/provider.go`
- `internal/sync/engine.go`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Add new parser/provider Go files (e.g., internal/parser/<provider>_provider.go, internal/parser/<provider>.go).
- Update provider registry or discovery (e.g., internal/parser/provider.go).
- Add or update test data and test cases (e.g., internal/parser/testdata/<provider>/*.json, internal/parser/<provider>_test.go).
- Integrate with sync engine if needed (e.g., internal/sync/engine.go).
- Update documentation and format sources (e.g., docs/internal/session-format-sources.md, docs/configuration.md).

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.