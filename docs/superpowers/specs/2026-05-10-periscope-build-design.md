# Periscope Fork — Build System Design Spec

- **Status:** Approved for implementation
- **Date:** 2026-05-10
- **Branch:** `merged` in `diazMelgarejo/periscope`
- **Architecture ref:** [`docs/ARCHITECTURE.md`](../../ARCHITECTURE.md)

---

## Context

`diazMelgarejo/periscope` is a fork of `latentsignal-org/periscope` (which is
itself a fork of `wesm/agentsview`). This spec covers the build system,
release pipeline, and tooling layered on top of the upstream codebase.

It does NOT cover Periscope product features (ContextPage, ActivityMinimap,
LLM summarizer) — those are specified in `docs/periscope-spec.md` and
`docs/periscope-v1-plan.md`. This spec covers everything needed to build,
release, and maintain the fork sustainably.

---

## Scope

### In scope (Layer 3 additions)

1. **Module & binary rename** — `github.com/wesm/agentsview` → `github.com/latentsignal-org/periscope`, binary `agentsview` → `periscope`
2. **`scripts/sync-upstream.sh`** — repeatable upstream merge with interactive conflict resolution on unknown files
3. **`scripts/install.sh` update** — points at `diazMelgarejo/periscope` releases; falls back to source build
4. **GitHub Actions `release.yml` update** — builds `periscope-{os}-{arch}` on `v*` tags, attaches JetBrains plugin zip
5. **`PeriscopeProcessManager.kt`** — JetBrains plugin: auto-start/stop periscope binary lifecycle
6. **Versioning scheme** — `v0.(upstream_minor+1).2-periscope.2`

### Out of scope (handled by existing plans)

- Periscope V1 context visualizer implementation → `periscope-v1-plan.md`
- Periscope V2 LLM guidance layer → `periscope-v2-llm-plan.md`
- macOS notarization / Tauri desktop → `desktop-release-setup.md`

---

## Architecture

See [`docs/ARCHITECTURE.md`](../../ARCHITECTURE.md) for the full matryoshka
diagram. Summary:

- **Layer 1:** `wesm/agentsview` — session indexing, parser framework, all registered agents, Go server + Svelte 5 frontend
- **Layer 2:** `latentsignal-org/periscope` — ContextPage, ActivityMinimap, LLM summarizer, JetBrains plugin scaffold, Periscope API routes
- **Layer 3:** this repo (`diazMelgarejo/periscope`) — module rename, sync automation, install script, CI, JetBrains lifecycle, versioning

---

## Decision Log

| # | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | Upstream sync strategy | Enhanced merge-based (Approach 1) | Matches existing workflow; conflict playbook already proven |
| D2 | Unknown conflict handling | Ask user interactively, wait for decision | Safety; no auto-resolution of unknown files |
| D3 | Module path | `github.com/latentsignal-org/periscope` | Matches `plugin.xml` `org.latentsignal.periscope`; canonical identity |
| D4 | Binary name | `periscope` | Matches product name |
| D5 | Versioning | `v0.(upstream_minor+1).2-periscope.2` | Readable upstream base; clear Periscope generation marker |
| D6 | Release binaries | GitHub Actions on `v*` tags; fallback to `make build` from source | B+C: canonical + fallback |
| D7 | JetBrains plugin lifecycle | Full auto-start/stop (Option C) | Most polished; matches DB/language-server plugin UX pattern |
| D8 | Deprecated code policy | Preserve if any Periscope feature depends on it | Periscope correctness over codebase tidiness |

---

## Component Designs

### 1. Module & Binary Rename

**One-time operation.** Run once on the `merged` branch.

```bash
# Update go.mod module path
go mod edit -module github.com/latentsignal-org/periscope

# Update all internal import paths (~100+ .go files)
find . -name "*.go" -not -path "./.git/*" | xargs sed -i '' \
  's|github.com/wesm/agentsview|github.com/latentsignal-org/periscope|g'

# Rename cmd/ directory
git mv cmd/agentsview cmd/periscope

# Update Makefile binary references
sed -i '' 's/agentsview/periscope/g' Makefile

# Add Version var to cmd/periscope/main.go
# (inject at build time: -ldflags "-X main.Version=v0.29.2-periscope.2")
```

**Verification:**
```bash
go build -tags fts5 ./...          # must compile cleanly
./periscope --version              # must print v0.29.2-periscope.2
```

---

### 2. `scripts/sync-upstream.sh`

**Runs after every upstream release.**

```bash
#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-main}"
MERGE_BRANCH="merged"
AGENTSVIEW_BRANCH="agentsview"

# Known-patterns table: file_pattern -> resolution
# Resolutions: HEAD (keep ours), UPSTREAM (take theirs), BOTH (union — manual)
declare -A KNOWN_PATTERNS=(
  ["README.md"]="HEAD"
  ["CLAUDE.md"]="HEAD"
  ["AGENTS.md"]="HEAD"
  ["frontend/vite.config.ts"]="HEAD"
  ["frontend/src/App.svelte"]="BOTH"
  ["frontend/src/lib/api/types/index.ts"]="BOTH"
  ["internal/parser/types.go"]="UPSTREAM"
  ["internal/parser/codex.go"]="UPSTREAM"
  ["internal/parser/codex_parser_test.go"]="UPSTREAM"
  ["internal/sync/engine.go"]="UPSTREAM"
  ["internal/postgres/push.go"]="UPSTREAM"
  ["internal/db/db.go"]="UPSTREAM"          # dataVersion: take theirs if higher
  ["internal/db/sessions.go"]="BOTH"        # IncrementalInfo: union
  ["internal/server/server.go"]="BOTH"      # routes + imports: additive
)

echo "==> Fetching upstream..."
git fetch "$UPSTREAM_REMOTE"

echo "==> Updating $AGENTSVIEW_BRANCH to track upstream exactly..."
git branch -f "$AGENTSVIEW_BRANCH" "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
git push origin "$AGENTSVIEW_BRANCH" --force

echo "==> Switching to $MERGE_BRANCH..."
git checkout "$MERGE_BRANCH"

echo "==> Merging upstream/main (no-commit to allow conflict resolution)..."
git merge "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" --no-commit --no-ff || true

CONFLICTS=$(git diff --name-only --diff-filter=U 2>/dev/null)

if [ -z "$CONFLICTS" ]; then
  echo "==> No conflicts. Clean merge."
  git commit -m "merge: upstream $UPSTREAM_REMOTE/$UPSTREAM_BRANCH into periscope (merged branch)"
  exit 0
fi

echo "==> Resolving conflicts..."
UNRESOLVED=()

for FILE in $CONFLICTS; do
  RESOLUTION="${KNOWN_PATTERNS[$FILE]:-UNKNOWN}"
  case "$RESOLUTION" in
    HEAD)
      echo "  [auto] $FILE → keep ours"
      git checkout HEAD -- "$FILE"
      ;;
    UPSTREAM)
      echo "  [auto] $FILE → take upstream"
      git checkout "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" -- "$FILE"
      ;;
    BOTH)
      echo "  [manual needed] $FILE → union (see conflict markers)"
      UNRESOLVED+=("$FILE")
      ;;
    UNKNOWN)
      UNRESOLVED+=("$FILE")
      ;;
  esac
done

# Interactive resolution for unknown/BOTH files
for FILE in "${UNRESOLVED[@]}"; do
  echo ""
  echo "════════════════════════════════════════"
  echo "CONFLICT: $FILE"
  echo "Pattern: ${KNOWN_PATTERNS[$FILE]:-UNKNOWN}"
  echo "════════════════════════════════════════"
  git diff -- "$FILE" || true
  echo ""
  echo "Options:"
  echo "  [k] Keep ours (HEAD)"
  echo "  [t] Take theirs (upstream)"
  echo "  [e] Open in editor to resolve manually"
  echo "  [s] Skip (leave conflict markers — you'll fix before committing)"
  echo "  [q] Quit sync script"
  read -rp "Your choice: " CHOICE

  case "$CHOICE" in
    k) git checkout HEAD -- "$FILE"; echo "  → kept ours" ;;
    t) git checkout "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" -- "$FILE"; echo "  → took theirs" ;;
    e) "${EDITOR:-vim}" "$FILE"; git add "$FILE"; echo "  → edited manually" ;;
    s) echo "  → skipped (resolve before committing)" ;;
    q) echo "Aborted."; exit 1 ;;
    *) echo "Unknown choice, skipping."; ;;
  esac
done

# Check if any conflict markers remain
REMAINING=$(grep -rl "<<<<<<< " . --include="*.go" --include="*.svelte" --include="*.ts" 2>/dev/null | grep -v ".git" || true)
if [ -n "$REMAINING" ]; then
  echo ""
  echo "==> Unresolved conflict markers remain in:"
  echo "$REMAINING"
  echo "Fix these, then run: git add . && git commit"
  exit 1
fi

git add -A
git commit -m "merge: upstream $UPSTREAM_REMOTE/$UPSTREAM_BRANCH into periscope (merged branch)

Conflict resolutions:
$(for f in $CONFLICTS; do echo "  - $f: ${KNOWN_PATTERNS[$f]:-INTERACTIVE}"; done)"

echo "==> Sync complete. Remember to bump version in cmd/periscope/main.go"
```

---

### 3. `scripts/install.sh` (updated)

Key changes from upstream's version:

```bash
REPO="diazMelgarejo/periscope"
BINARY_NAME="periscope"

# ... detect OS/ARCH ...

RELEASE_URL="https://github.com/${REPO}/releases/latest/download/${BINARY_NAME}-${OS}-${ARCH}${EXT}"

if curl --head --silent --fail "$RELEASE_URL" > /dev/null 2>&1; then
    echo "Downloading pre-built binary..."
    curl -fL "$RELEASE_URL" -o "$BINARY_NAME"
    chmod +x "$BINARY_NAME"
else
    echo "No release binary found. Building from source (requires Go 1.26+ and Node 20+)..."
    TMPDIR=$(mktemp -d)
    git clone --branch merged --depth 1 \
      "https://github.com/${REPO}.git" "$TMPDIR/periscope-src"
    cd "$TMPDIR/periscope-src"
    make frontend
    CGO_ENABLED=1 go build -tags fts5 \
      -ldflags "-X main.Version=$(git describe --tags --always)" \
      -o "$BINARY_NAME" ./cmd/periscope
    cp "$BINARY_NAME" -
    cd -
    rm -rf "$TMPDIR"
fi

# Install
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
mkdir -p "$INSTALL_DIR"
mv "$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
echo "Installed: $INSTALL_DIR/$BINARY_NAME"
```

---

### 4. GitHub Actions `release.yml` (updated)

Key changes from upstream:

```yaml
name: Release
on:
  push:
    tags: ['v*']

jobs:
  build:
    strategy:
      matrix:
        include:
          - os: ubuntu-latest
            goos: linux
            goarch: amd64
            output: periscope-linux-amd64
          - os: ubuntu-latest
            goos: linux
            goarch: arm64
            output: periscope-linux-arm64
          - os: macos-latest
            goos: darwin
            goarch: arm64
            output: periscope-darwin-arm64
          - os: windows-latest
            goos: windows
            goarch: amd64
            output: periscope-windows-amd64.exe
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: '1.26' }
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - name: Build frontend
        run: make frontend
      - name: Build binary
        env:
          GOOS: ${{ matrix.goos }}
          GOARCH: ${{ matrix.goarch }}
          CGO_ENABLED: 1
        run: |
          go build -tags fts5 \
            -ldflags "-X main.Version=${{ github.ref_name }}" \
            -o ${{ matrix.output }} \
            ./cmd/periscope
      - uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.output }}
          path: ${{ matrix.output }}

  jetbrains-plugin:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '21', distribution: 'temurin' }
      - name: Build plugin
        run: cd jetbrains-plugin && ./gradlew buildPlugin
      - uses: actions/upload-artifact@v4
        with:
          name: periscope-jetbrains-plugin
          path: jetbrains-plugin/build/distributions/*.zip

  release:
    needs: [build, jetbrains-plugin]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
      - uses: softprops/action-gh-release@v2
        with:
          files: |
            periscope-linux-amd64/periscope-linux-amd64
            periscope-linux-arm64/periscope-linux-arm64
            periscope-darwin-arm64/periscope-darwin-arm64
            periscope-windows-amd64.exe/periscope-windows-amd64.exe
            periscope-jetbrains-plugin/*.zip
```

---

### 5. `PeriscopeProcessManager.kt`

Replaces the placeholder `MyProjectActivity.kt`. Full Kotlin object:

```kotlin
package org.latentsignal.periscope

import com.intellij.notification.NotificationGroupManager
import com.intellij.notification.NotificationType
import com.intellij.openapi.Disposable
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.project.Project
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.nio.file.Files
import kotlin.concurrent.thread

object PeriscopeProcessManager : Disposable {
    private val LOG = logger<PeriscopeProcessManager>()
    private var process: Process? = null
    private const val PORT = 8080
    private const val POLL_INTERVAL_MS = 500L
    private const val POLL_MAX_ATTEMPTS = 20 // 10 seconds

    fun start(project: Project): Boolean {
        if (isRunning()) {
            LOG.info("Periscope already running on port $PORT")
            return true
        }
        val binary = findBinary() ?: run {
            notify(project, "Periscope binary not found. Run: curl -fsSL https://raw.githubusercontent.com/diazMelgarejo/periscope/merged/scripts/install.sh | bash", NotificationType.ERROR)
            return false
        }
        LOG.info("Starting periscope binary: $binary")
        process = ProcessBuilder(binary, "--port", PORT.toString(), "--data-dir", project.basePath ?: "~/.periscope")
            .redirectErrorStream(true)
            .start()
        return pollUntilReady()
    }

    fun stop() {
        process?.let { p ->
            LOG.info("Stopping periscope...")
            p.destroy()
            if (!p.waitFor(3, java.util.concurrent.TimeUnit.SECONDS)) {
                p.destroyForcibly()
            }
            process = null
        }
    }

    fun serverUrl(): String = "http://localhost:$PORT"

    private fun isRunning(): Boolean = try {
        (URL("http://localhost:$PORT/api/v1/sessions").openConnection() as HttpURLConnection)
            .also { it.connectTimeout = 500 }.responseCode == 200
    } catch (e: Exception) { false }

    private fun pollUntilReady(): Boolean {
        repeat(POLL_MAX_ATTEMPTS) {
            if (isRunning()) return true
            Thread.sleep(POLL_INTERVAL_MS)
        }
        LOG.warn("Periscope did not start within ${POLL_MAX_ATTEMPTS * POLL_INTERVAL_MS}ms")
        return false
    }

    private fun findBinary(): String? {
        val candidates = listOf(
            System.getenv("PERISCOPE_BIN"),
            "${System.getProperty("user.home")}/.local/bin/periscope",
            "/usr/local/bin/periscope",
        )
        return candidates.filterNotNull().firstOrNull { File(it).canExecute() }
    }

    private fun notify(project: Project, message: String, type: NotificationType) {
        NotificationGroupManager.getInstance()
            .getNotificationGroup("Periscope")
            .createNotification(message, type)
            .notify(project)
    }

    override fun dispose() = stop()
}
```

**`MyToolWindowFactory.kt` update:**

```kotlin
// Replace hardcoded localhost:5173 with PeriscopeProcessManager
override fun createToolWindowContent(project: Project, toolWindow: ToolWindow) {
    PeriscopeProcessManager.start(project)
    val browser = JBCefBrowser(PeriscopeProcessManager.serverUrl())
    // ... add to tool window ...
}
```

---

## Testing Plan

### Rename verification
- `go build -tags fts5 ./...` compiles with no import errors
- `./periscope --version` prints `v0.29.2-periscope.2`
- `grep -r "wesm/agentsview" --include="*.go" .` returns zero results

### Sync script verification
- Run against a test repo where a known conflict file is present → auto-resolved correctly
- Introduce a file not in the known-patterns table → script stops and prompts
- User chooses "keep ours" → file preserved, merge commits cleanly

### Install script verification
- With a release present: binary downloads and installs to `~/.local/bin/periscope`
- Without a release (fresh fork): source build runs, binary installs
- Installed binary: `periscope --version` prints correct version

### CI verification
- Push `v0.29.2-periscope.2` tag to fork → 4 platform builds + plugin zip attach to release
- Download `periscope-darwin-arm64` → `./periscope-darwin-arm64 --version` works

### JetBrains plugin verification
- Open a project in IDEA → periscope binary starts within 10s
- Context tab loads `localhost:8080`
- Close IDEA → `pgrep periscope` returns nothing
- Binary not installed → notification appears with install instructions

---

## Implementation Order

1. **Module + binary rename** (one-time) — do first; blocks everything else
2. **`cmd/periscope/main.go` Version var** — wire `-ldflags` injection
3. **`Makefile` updates** — binary name, version ldflags target
4. **`scripts/install.sh`** — update REPO + BINARY_NAME + fallback path
5. **`scripts/sync-upstream.sh`** — new file; make executable (`chmod +x`)
6. **`.github/workflows/release.yml`** — update matrix + binary names
7. **`PeriscopeProcessManager.kt`** — replace MyProjectActivity.kt logic
8. **`MyToolWindowFactory.kt`** — wire PeriscopeProcessManager.serverUrl()
9. **Tag and push `v0.29.2-periscope.2`** — trigger first CI release
10. **Test install script end-to-end** on clean Mac
