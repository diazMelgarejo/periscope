package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
)

// TestBenchPRCallerStaysLocal locks the security-sensitive workflow change:
// pull requests must call this repository's bench workflow, and that workflow
// must keep taking sample count and benchtime from `make bench-gate-config`.
// The retired kenn-io/agentsview@main pin failed closed twice: it required
// BENCH_GATE_HEAVY under `set -u`, which this Makefile does not emit, and
// then the upstream file was deleted.
func TestBenchPRCallerStaysLocal(t *testing.T) {
	root := repoRoot(t)
	caller := readRepoFile(t, root, ".github/workflows/bench-pr.yml")
	called := readRepoFile(t, root, ".github/workflows/bench.yml")

	require.Equal(t, "./.github/workflows/bench.yml", workflowUses(t, caller))
	require.NotContains(t, caller, "pull_request_target")
	require.Equal(t, "permissions: read-all", workflowPermissions(t, caller),
		"the caller ceiling stays read-only, matching the other PR dispatcher; "+
			"bench.yml narrows the job token to contents: read")

	require.Contains(t, called, "workflow_call:")
	require.Contains(t, called, "make -s bench-gate-config")
	require.Contains(t, called, `BENCH_GATE_COUNT="$BENCH_GATE_COUNT"`)
	require.Contains(t, called, `BENCH_GATE_TIME="$BENCH_GATE_TIME"`)
	require.NotContains(t, called, "BENCH_GATE_HEAVY")
	require.Contains(t, called, "permissions:")
	require.Contains(t, called, "contents: read")
	require.NotContains(t, called, "contents: write")

	cmd := exec.Command("make", "-s", "bench-gate-config")
	cmd.Dir = root
	out, err := cmd.Output()
	require.NoError(t, err)
	got := strings.TrimSpace(string(out))
	require.Regexp(t,
		regexp.MustCompile(`^BENCH_GATE_COUNT=[0-9]+ BENCH_GATE_TIME=[0-9]+x$`),
		got,
	)
	require.NotContains(t, got, "BENCH_GATE_HEAVY")
}

func repoRoot(t *testing.T) string {
	t.Helper()
	dir, err := os.Getwd()
	require.NoError(t, err)
	for {
		if _, statErr := os.Stat(filepath.Join(dir, "go.mod")); statErr == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		require.NotEqual(t, parent, dir, "go.mod not found above %s", dir)
		dir = parent
	}
}

func readRepoFile(t *testing.T, root, rel string) string {
	t.Helper()
	body, err := os.ReadFile(filepath.Join(root, rel))
	require.NoError(t, err)
	return string(body)
}

func workflowUses(t *testing.T, body string) string {
	t.Helper()
	for _, line := range strings.Split(body, "\n") {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "#") {
			continue
		}
		if strings.HasPrefix(trimmed, "uses:") {
			return strings.TrimSpace(strings.TrimPrefix(trimmed, "uses:"))
		}
	}
	t.Fatal("workflow has no uses: line")
	return ""
}

func workflowPermissions(t *testing.T, body string) string {
	t.Helper()
	for _, line := range strings.Split(body, "\n") {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "#") {
			continue
		}
		if strings.HasPrefix(trimmed, "permissions:") {
			return trimmed
		}
	}
	t.Fatal("workflow has no permissions: line")
	return ""
}
