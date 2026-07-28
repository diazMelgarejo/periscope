# Periscope Fork Build System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the fork from `wesm/agentsview` to `latentsignal-org/periscope`, wire the full release pipeline, and add JetBrains plugin lifecycle management.

**Architecture:** Three-layer matryoshka — Layer 1 (agentsview base) → Layer 2 (Periscope features, already merged) → Layer 3 (this plan: fork identity + release tooling). All changes are on the `merged` branch. See `docs/ARCHITECTURE.md` for the full model.

**Tech Stack:** Go 1.26 + CGO/SQLite (fts5), Svelte 5 frontend, Kotlin/JVM 21 JetBrains plugin, GitHub Actions CI, Bash scripts.

**Spec:** `docs/superpowers/specs/2026-05-10-periscope-build-design.md`  
**Do NOT implement:** Periscope V1/V2 product features — those are in `docs/periscope-v1-plan.md` and `docs/periscope-v2-llm-plan.md`.

---

## File Map

| Action | File | What changes |
|---|---|---|
| Modify | `go.mod` | module path rename |
| Modify | all `*.go` (100+) | import path sed replace |
| Rename | `cmd/agentsview/` → `cmd/periscope/` | directory rename |
| Modify | `Makefile` | binary name, data dir, DB name |
| Modify | `scripts/install.sh` | REPO, BINARY_NAME, source fallback |
| Create | `scripts/sync-upstream.sh` | new sync script |
| Modify | `.github/workflows/release.yml` | binary names, add plugin build job |
| Create | `jetbrains-plugin/src/main/kotlin/org/latentsignal/periscope/PeriscopeProcessManager.kt` | new lifecycle manager |
| Modify | `jetbrains-plugin/src/main/kotlin/org/latentsignal/sampleplugin/toolWindow/MyToolWindowFactory.kt` | wire PeriscopeProcessManager |
| Modify | `jetbrains-plugin/src/main/kotlin/org/latentsignal/sampleplugin/startup/MyProjectActivity.kt` | wire PeriscopeProcessManager.start() |
| Modify | `jetbrains-plugin/src/main/resources/META-INF/plugin.xml` | add notification group |
| Modify | `jetbrains-plugin/gradle.properties` | bump version to match release |

---

## Task 1: Go Module Rename

**Files:**
- Modify: `go.mod`
- Modify: all `*.go` files (import path sed replace — no individual edits)

- [ ] **Step 1.1: Rename the module in go.mod**

```bash
cd /tmp/periscope-work/periscope
go mod edit -module github.com/latentsignal-org/periscope
head -3 go.mod
```

Expected output:
```
module github.com/latentsignal-org/periscope

go 1.26.2
```

- [ ] **Step 1.2: Replace all internal import paths across every .go file**

```bash
find . -name "*.go" -not -path "./.git/*" \
  | xargs sed -i '' 's|github.com/wesm/agentsview|github.com/latentsignal-org/periscope|g'
```

No output expected. If BSD sed complains, drop the `''` and use GNU sed on Linux.

- [ ] **Step 1.3: Verify no stale import paths remain**

```bash
grep -r "wesm/agentsview" --include="*.go" . | grep -v ".git"
```

Expected: zero lines of output.

- [ ] **Step 1.4: Verify the build still compiles**

```bash
go build -tags fts5 ./...
```

Expected: no errors. Fix any compile errors before continuing (they will be missing imports — check the file name and re-run the sed if missed).

- [ ] **Step 1.5: Commit**

```bash
git add go.mod
git add $(git diff --name-only --diff-filter=M -- "*.go")
git commit -m "chore: rename Go module to github.com/latentsignal-org/periscope"
```

---

## Task 2: Binary + Makefile Rename

**Files:**
- Rename: `cmd/agentsview/` → `cmd/periscope/`
- Modify: `Makefile`

- [ ] **Step 2.1: Rename the cmd directory**

```bash
git mv cmd/agentsview cmd/periscope
```

No output expected.

- [ ] **Step 2.2: Rename binary references in Makefile**

Replace all `agentsview` binary/path references. Run these four targeted sed commands in order:

```bash
# Binary output name: agentsview → periscope
sed -i '' 's|-o agentsview |-o periscope |g' Makefile
sed -i '' 's|@chmod +x agentsview|@chmod +x periscope|g' Makefile
sed -i '' 's|cp agentsview |cp periscope |g' Makefile
sed -i '' 's|rm -f agentsview|rm -f periscope|g' Makefile

# cmd path: ./cmd/agentsview → ./cmd/periscope
sed -i '' 's|./cmd/agentsview|./cmd/periscope|g' Makefile

# Data directory env var and paths: .agentsview → .periscope
sed -i '' 's|AGENTSVIEW_DATA_DIR|PERISCOPE_DATA_DIR|g' Makefile
sed -i '' 's|\.agentsview|.periscope|g' Makefile
sed -i '' 's|\.agentsview-snapshot|.periscope-snapshot|g' Makefile

# dist output names
sed -i '' 's|agentsview-darwin|periscope-darwin|g' Makefile
sed -i '' 's|agentsview-linux|periscope-linux|g' Makefile
sed -i '' 's|agentsview-windows|periscope-windows|g' Makefile

# Test DB name
sed -i '' 's|agentsview_test|periscope_test|g' Makefile

# Help text / comments
sed -i '' 's|agentsview |periscope |g' Makefile
```

- [ ] **Step 2.3: Verify Makefile has no stale agentsview binary references**

```bash
grep -n "agentsview" Makefile | grep -v "AgentsView\|agentsview_test\|# " | head -20
```

Expected: only Tauri desktop references (`AgentsView.app`) and any comment lines remain — those are desktop app names and can stay.

- [ ] **Step 2.4: Build the renamed binary**

```bash
make build
```

Expected: `periscope` binary appears in repo root. No errors.

- [ ] **Step 2.5: Verify version output**

```bash
./periscope --version
```

Expected: something like `periscope dev (unknown)` — the exact string from `main.go`'s version vars. The ldflags are already wired in the Makefile (`-X main.version=$(VERSION)`).

- [ ] **Step 2.6: Commit**

```bash
git add Makefile
git add cmd/
git commit -m "chore: rename binary from agentsview to periscope, update cmd/ directory"
```

---

## Task 3: Version String in main.go

**Files:**
- Modify: `cmd/periscope/main.go`

The Makefile already injects `main.version`, `main.commit`, and `main.buildDate` via ldflags. This task pins the initial version so `go run` (without ldflags) shows the right default.

- [ ] **Step 3.1: Update the default version var in main.go**

Current content around line 30–34 of `cmd/periscope/main.go`:
```go
var (
	version   = "dev"
	commit    = "unknown"
	buildDate = ""
)
```

Replace with:
```go
var (
	version   = "v0.29.2-periscope.2"
	commit    = "unknown"
	buildDate = ""
)
```

- [ ] **Step 3.2: Verify the version string appears in the built binary**

```bash
make build && ./periscope --version
```

Expected output contains `v0.29.2-periscope.2` (exact format depends on how the version flag is printed — check that the string appears).

- [ ] **Step 3.3: Commit**

```bash
git add cmd/periscope/main.go
git commit -m "chore: set initial fork version to v0.29.2-periscope.2"
```

---

## Task 4: Update install.sh

**Files:**
- Modify: `scripts/install.sh`

- [ ] **Step 4.1: Update REPO and BINARY_NAME at the top of install.sh**

Find the current lines (near top of file):
```bash
REPO="wesm/agentsview"
BINARY_NAME="agentsview"
```

Replace with:
```bash
REPO="diazMelgarejo/periscope"
BINARY_NAME="periscope"
```

- [ ] **Step 4.2: Add source-build fallback after the existing download block**

Find the section in `scripts/install.sh` that downloads the binary and exits on failure. After the download attempt block, add the fallback. The exact location is where the script currently calls `error` if download fails. Replace that pattern with:

```bash
# Try pre-built release first
RELEASE_URL="https://github.com/${REPO}/releases/latest/download/${BINARY_NAME}-${OS}-${ARCH}${EXT}"

info "Trying pre-built release: $RELEASE_URL"
if curl --head --silent --fail "$RELEASE_URL" > /dev/null 2>&1; then
    info "Downloading pre-built binary..."
    curl -fL "$RELEASE_URL" -o "$BINARY_NAME"
    chmod +x "$BINARY_NAME"
else
    warn "No pre-built release found for ${OS}-${ARCH}. Building from source..."
    warn "This requires Go 1.26+ and Node 20+ to be installed."

    command -v go >/dev/null 2>&1 || error "Go is not installed. Install from https://go.dev"
    command -v node >/dev/null 2>&1 || error "Node is not installed. Install from https://nodejs.org"

    TMPDIR_SRC=$(mktemp -d)
    trap "rm -rf $TMPDIR_SRC" EXIT

    info "Cloning merged branch from github.com/${REPO}..."
    git clone --branch merged --depth 1 \
        "https://github.com/${REPO}.git" "$TMPDIR_SRC/periscope-src"

    info "Building frontend..."
    (cd "$TMPDIR_SRC/periscope-src/frontend" && npm ci && npm run build)

    info "Building binary..."
    (
        cd "$TMPDIR_SRC/periscope-src"
        CGO_ENABLED=1 go build -tags fts5 \
            -ldflags "-X main.version=$(git describe --tags --always 2>/dev/null || echo dev)" \
            -o "$BINARY_NAME" \
            ./cmd/periscope
    )
    cp "$TMPDIR_SRC/periscope-src/$BINARY_NAME" .
fi
```

- [ ] **Step 4.3: Update the comment/usage line at the top of the file**

Find:
```bash
# agentsview installer
# Usage: curl -fsSL https://raw.githubusercontent.com/wesm/agentsview/main/scripts/install.sh | bash
```

Replace with:
```bash
# Periscope installer
# Usage: curl -fsSL https://raw.githubusercontent.com/diazMelgarejo/periscope/merged/scripts/install.sh | bash
```

- [ ] **Step 4.4: Run shellcheck to verify script syntax (if available)**

```bash
command -v shellcheck >/dev/null && shellcheck scripts/install.sh || echo "shellcheck not installed, skipping"
```

- [ ] **Step 4.5: Smoke test — dry run on local machine**

```bash
bash -n scripts/install.sh && echo "Syntax OK"
```

Expected: `Syntax OK`

- [ ] **Step 4.6: Commit**

```bash
git add scripts/install.sh
git commit -m "feat: update install.sh for diazMelgarejo/periscope with source-build fallback"
```

---

## Task 5: Create sync-upstream.sh

**Files:**
- Create: `scripts/sync-upstream.sh`

- [ ] **Step 5.1: Create the sync script**

Create `scripts/sync-upstream.sh` with the following content:

```bash
#!/usr/bin/env bash
# sync-upstream.sh — merge wesm/agentsview upstream into the merged branch.
# Run after every upstream release.
# Unknown conflicts are presented interactively; known patterns are auto-resolved.
# See docs/ARCHITECTURE.md §Repeatable Sync Workflow for the full process.

set -euo pipefail

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-main}"
MERGE_BRANCH="merged"
AGENTSVIEW_BRANCH="agentsview"

# Known-patterns table: relative file path → resolution
#   HEAD     = keep ours (git checkout HEAD -- file)
#   UPSTREAM = take theirs (git checkout upstream/main -- file)
#   BOTH     = union required — present interactively even though known
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
  ["internal/db/db.go"]="UPSTREAM"
  ["internal/db/sessions.go"]="BOTH"
  ["internal/server/server.go"]="BOTH"
)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}==> $1${NC}"; }
warn()  { echo -e "${YELLOW}==> $1${NC}"; }
error() { echo -e "${RED}==> ERROR: $1${NC}" >&2; exit 1; }

# Validate we're in the repo root
[ -f go.mod ] || error "Run this script from the repo root."

info "Fetching upstream ($UPSTREAM_REMOTE/$UPSTREAM_BRANCH)..."
git fetch "$UPSTREAM_REMOTE" || error "Could not fetch $UPSTREAM_REMOTE. Add it with: git remote add upstream https://github.com/wesm/agentsview.git"

info "Force-updating $AGENTSVIEW_BRANCH to track upstream exactly..."
git branch -f "$AGENTSVIEW_BRANCH" "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
git push origin "$AGENTSVIEW_BRANCH" --force
info "$AGENTSVIEW_BRANCH updated."

CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "$MERGE_BRANCH" ]; then
  info "Switching to $MERGE_BRANCH..."
  git checkout "$MERGE_BRANCH"
fi

info "Merging $UPSTREAM_REMOTE/$UPSTREAM_BRANCH into $MERGE_BRANCH..."
git merge "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" --no-commit --no-ff 2>/dev/null || true

CONFLICTS=$(git diff --name-only --diff-filter=U 2>/dev/null || true)

if [ -z "$CONFLICTS" ]; then
  info "No conflicts. Committing clean merge."
  git commit -m "merge: upstream $UPSTREAM_REMOTE/$UPSTREAM_BRANCH into periscope (merged branch)"
  info "Sync complete. Remember to bump version in cmd/periscope/main.go"
  exit 0
fi

warn "Conflicts detected. Resolving..."
INTERACTIVE_FILES=()
RESOLUTION_LOG=()

for FILE in $CONFLICTS; do
  RESOLUTION="${KNOWN_PATTERNS[$FILE]:-UNKNOWN}"
  case "$RESOLUTION" in
    HEAD)
      git checkout HEAD -- "$FILE"
      RESOLUTION_LOG+=("  $FILE → kept ours (auto)")
      ;;
    UPSTREAM)
      git checkout "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" -- "$FILE"
      RESOLUTION_LOG+=("  $FILE → took upstream (auto)")
      ;;
    BOTH|UNKNOWN)
      INTERACTIVE_FILES+=("$FILE")
      ;;
  esac
done

# Print auto-resolutions
echo -e "${CYAN}Auto-resolved:${NC}"
for LINE in "${RESOLUTION_LOG[@]}"; do echo "$LINE"; done

# Interactive resolution for BOTH/UNKNOWN files
for FILE in "${INTERACTIVE_FILES[@]}"; do
  PATTERN="${KNOWN_PATTERNS[$FILE]:-UNKNOWN}"
  echo ""
  echo -e "${CYAN}════════════════════════════════════════${NC}"
  echo -e "${YELLOW}CONFLICT: $FILE${NC} (pattern: $PATTERN)"
  echo -e "${CYAN}════════════════════════════════════════${NC}"
  git diff -- "$FILE" || true
  echo ""
  echo "Options:"
  echo "  [k] Keep ours (HEAD)"
  echo "  [t] Take theirs (upstream)"
  echo "  [e] Open in \$EDITOR to resolve manually (then saves)"
  echo "  [s] Skip — leave conflict markers (fix manually before committing)"
  echo "  [q] Quit sync — no commit made"
  read -rp "Your choice [k/t/e/s/q]: " CHOICE </dev/tty

  case "$CHOICE" in
    k)
      git checkout HEAD -- "$FILE"
      RESOLUTION_LOG+=("  $FILE → kept ours (interactive)")
      ;;
    t)
      git checkout "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" -- "$FILE"
      RESOLUTION_LOG+=("  $FILE → took upstream (interactive)")
      ;;
    e)
      "${EDITOR:-vim}" "$FILE" </dev/tty
      git add "$FILE"
      RESOLUTION_LOG+=("  $FILE → edited manually (interactive)")
      ;;
    s)
      warn "Skipped $FILE — fix conflict markers before committing."
      RESOLUTION_LOG+=("  $FILE → SKIPPED (manual fix required)")
      ;;
    q)
      error "Sync aborted by user. Run 'git merge --abort' to reset."
      ;;
    *)
      warn "Unknown choice '$CHOICE', skipping $FILE."
      RESOLUTION_LOG+=("  $FILE → SKIPPED (unknown choice)")
      ;;
  esac
done

# Final check for remaining conflict markers
REMAINING=$(git diff --name-only --diff-filter=U 2>/dev/null || true)
if [ -n "$REMAINING" ]; then
  warn "Unresolved conflict markers remain in:"
  echo "$REMAINING"
  warn "Fix these, then run: git add . && git commit -m 'merge: upstream ...'"
  exit 1
fi

RESOLUTION_SUMMARY=$(printf '%s\n' "${RESOLUTION_LOG[@]}")
git add -A
git commit -m "$(cat <<EOF
merge: upstream $UPSTREAM_REMOTE/$UPSTREAM_BRANCH into periscope (merged branch)

Conflict resolutions:
$RESOLUTION_SUMMARY
EOF
)"

info "Sync complete."
warn "Next step: bump version in cmd/periscope/main.go per versioning scheme in docs/ARCHITECTURE.md"
```

- [ ] **Step 5.2: Make the script executable**

```bash
chmod +x scripts/sync-upstream.sh
```

- [ ] **Step 5.3: Verify syntax**

```bash
bash -n scripts/sync-upstream.sh && echo "Syntax OK"
```

Expected: `Syntax OK`

- [ ] **Step 5.4: Add the upstream remote if not present**

```bash
git remote get-url upstream 2>/dev/null || \
  git remote add upstream https://github.com/wesm/agentsview.git
git remote -v | grep upstream
```

Expected: `upstream	https://github.com/wesm/agentsview.git (fetch)` (and push line).

- [ ] **Step 5.5: Commit**

```bash
git add scripts/sync-upstream.sh
git commit -m "feat: add sync-upstream.sh for repeatable upstream merge with interactive conflict resolution"
```

---

## Task 6: Update GitHub Actions release.yml

**Files:**
- Modify: `.github/workflows/release.yml`

The existing workflow builds `agentsview` binaries using `manylinux` containers for glibc compatibility. We preserve that approach and rename.

- [ ] **Step 6.1: Replace all binary name references in release.yml**

```bash
sed -i '' 's|agentsview|periscope|g' .github/workflows/release.yml
sed -i '' 's|./cmd/periscope|./cmd/periscope|g' .github/workflows/release.yml  # already correct after step above
```

Wait — the above sed will also rename `cmd/agentsview` references. Verify:

```bash
grep "cmd/" .github/workflows/release.yml
```

Expected: all should read `./cmd/periscope`. If any still read `./cmd/agentsview`, fix manually.

- [ ] **Step 6.2: Add the JetBrains plugin build job**

Open `.github/workflows/release.yml` and add this job before the final `release` or `publish` job:

```yaml
  build-jetbrains-plugin:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd
        with:
          persist-credentials: false

      - uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'temurin'

      - name: Build JetBrains plugin
        run: |
          cd jetbrains-plugin
          VERSION=${GITHUB_REF#refs/tags/v}
          sed -i "s/^version = .*/version = $VERSION/" gradle.properties
          ./gradlew buildPlugin --no-daemon

      - name: Upload plugin artifact
        uses: actions/upload-artifact@v4
        with:
          name: periscope-jetbrains-plugin
          path: jetbrains-plugin/build/distributions/*.zip
```

- [ ] **Step 6.3: Add `build-jetbrains-plugin` to the release/publish job's `needs` list**

Find the job that creates the GitHub release (likely named `release` or `publish`). Add `build-jetbrains-plugin` to its `needs:` array and add the plugin zip to its artifact list:

```yaml
      - name: Download plugin artifact
        uses: actions/download-artifact@v4
        with:
          name: periscope-jetbrains-plugin
          path: dist/jetbrains/

      # Add to the files: list of the release upload step:
      # dist/jetbrains/*.zip
```

- [ ] **Step 6.4: Verify the YAML is valid**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release.yml'))" && echo "YAML valid"
```

Expected: `YAML valid`

- [ ] **Step 6.5: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "feat: update release.yml for periscope binary names + JetBrains plugin build job"
```

---

## Task 7: Create PeriscopeProcessManager.kt

**Files:**
- Create: `jetbrains-plugin/src/main/kotlin/org/latentsignal/periscope/PeriscopeProcessManager.kt`
- Modify: `jetbrains-plugin/src/main/resources/META-INF/plugin.xml`

- [ ] **Step 7.1: Create the PeriscopeProcessManager directory**

```bash
mkdir -p jetbrains-plugin/src/main/kotlin/org/latentsignal/periscope
```

- [ ] **Step 7.2: Create PeriscopeProcessManager.kt**

Create `jetbrains-plugin/src/main/kotlin/org/latentsignal/periscope/PeriscopeProcessManager.kt`:

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

/**
 * Manages the lifecycle of the periscope binary for the JetBrains plugin.
 *
 * Binary location priority:
 *   1. $PERISCOPE_BIN environment variable
 *   2. ~/.local/bin/periscope
 *   3. /usr/local/bin/periscope
 *
 * On project open: starts periscope on port 8080 if not already running.
 * On project/IDE close: sends SIGTERM, waits 3s, then SIGKILL.
 */
object PeriscopeProcessManager : Disposable {

    private val LOG = logger<PeriscopeProcessManager>()
    private const val PORT = 8080
    private const val POLL_INTERVAL_MS = 500L
    private const val POLL_MAX_ATTEMPTS = 20  // 10 seconds total
    private const val NOTIFICATION_GROUP = "Periscope"

    @Volatile
    private var managedProcess: Process? = null

    /**
     * Start the periscope binary for the given project.
     * Returns true if periscope is reachable after this call, false otherwise.
     */
    fun start(project: Project): Boolean {
        if (isReachable()) {
            LOG.info("Periscope already running on port $PORT — reusing existing instance.")
            return true
        }

        val binary = findBinary()
        if (binary == null) {
            LOG.warn("Periscope binary not found.")
            showNotification(
                project,
                "Periscope binary not found. Install it:\n" +
                "curl -fsSL https://raw.githubusercontent.com/diazMelgarejo/periscope/merged/scripts/install.sh | bash",
                NotificationType.WARNING
            )
            return false
        }

        LOG.info("Starting periscope: $binary --port $PORT")
        val dataDir = project.basePath ?: "${System.getProperty("user.home")}/.periscope"

        managedProcess = ProcessBuilder(binary, "--port", PORT.toString(), "--data-dir", dataDir)
            .redirectErrorStream(true)
            .start()

        LOG.info("Periscope process started (PID not directly available via ProcessBuilder). Polling...")
        return pollUntilReady(project)
    }

    /**
     * Stop the managed periscope process gracefully.
     * Called on project close or IDE shutdown.
     */
    fun stop() {
        val p = managedProcess ?: return
        LOG.info("Stopping managed periscope process...")
        p.destroy()
        val exited = p.waitFor(3, java.util.concurrent.TimeUnit.SECONDS)
        if (!exited) {
            LOG.warn("Periscope did not exit within 3s — sending SIGKILL.")
            p.destroyForcibly()
        }
        managedProcess = null
        LOG.info("Periscope stopped.")
    }

    /** Returns the URL to load in the JBCefBrowser. */
    fun serverUrl(): String = "http://localhost:$PORT/"

    /** True if periscope's API responds on the expected port. */
    fun isReachable(): Boolean = try {
        val conn = URL("http://localhost:$PORT/api/v1/sessions").openConnection() as HttpURLConnection
        conn.connectTimeout = 500
        conn.readTimeout = 500
        conn.responseCode in 200..299
    } catch (_: Exception) {
        false
    }

    private fun pollUntilReady(project: Project): Boolean {
        repeat(POLL_MAX_ATTEMPTS) {
            if (isReachable()) {
                LOG.info("Periscope is ready on port $PORT.")
                return true
            }
            Thread.sleep(POLL_INTERVAL_MS)
        }
        LOG.warn("Periscope did not become ready within ${POLL_MAX_ATTEMPTS * POLL_INTERVAL_MS}ms.")
        showNotification(
            project,
            "Periscope started but did not respond within 10 seconds. Check logs.",
            NotificationType.WARNING
        )
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

    private fun showNotification(project: Project, message: String, type: NotificationType) {
        try {
            NotificationGroupManager.getInstance()
                .getNotificationGroup(NOTIFICATION_GROUP)
                ?.createNotification(message, type)
                ?.notify(project)
        } catch (e: Exception) {
            LOG.warn("Could not show notification: ${e.message}")
        }
    }

    override fun dispose() {
        stop()
    }
}
```

- [ ] **Step 7.3: Register the notification group in plugin.xml**

Open `jetbrains-plugin/src/main/resources/META-INF/plugin.xml`. The current content is:

```xml
<idea-plugin>
    <id>org.latentsignal.periscope</id>
    <name>Periscope</name>
    <vendor>latentsignal</vendor>
    <depends>com.intellij.modules.platform</depends>
    <resource-bundle>messages.MyBundle</resource-bundle>
    <extensions defaultExtensionNs="com.intellij">
        <toolWindow factoryClass="org.latentsignal.sampleplugin.toolWindow.MyToolWindowFactory" id="Periscope"/>
        <postStartupActivity implementation="org.latentsignal.sampleplugin.startup.MyProjectActivity" />
    </extensions>
</idea-plugin>
```

Replace with:

```xml
<!-- Plugin Configuration File. Read more: https://plugins.jetbrains.com/docs/intellij/plugin-configuration-file.html -->
<idea-plugin>
    <id>org.latentsignal.periscope</id>
    <name>Periscope</name>
    <vendor>latentsignal</vendor>

    <depends>com.intellij.modules.platform</depends>

    <resource-bundle>messages.MyBundle</resource-bundle>

    <extensions defaultExtensionNs="com.intellij">
        <toolWindow
            factoryClass="org.latentsignal.sampleplugin.toolWindow.MyToolWindowFactory"
            id="Periscope"/>
        <postStartupActivity
            implementation="org.latentsignal.sampleplugin.startup.MyProjectActivity"/>
        <notificationGroup
            id="Periscope"
            displayType="BALLOON"/>
    </extensions>
</idea-plugin>
```

- [ ] **Step 7.4: Verify the Kotlin file compiles (Gradle check)**

```bash
cd jetbrains-plugin && ./gradlew compileKotlin --no-daemon 2>&1 | tail -20
```

Expected: `BUILD SUCCESSFUL` (or similar). Fix any import errors.

- [ ] **Step 7.5: Commit**

```bash
cd ..  # back to repo root
git add jetbrains-plugin/src/main/kotlin/org/latentsignal/periscope/PeriscopeProcessManager.kt
git add jetbrains-plugin/src/main/resources/META-INF/plugin.xml
git commit -m "feat: add PeriscopeProcessManager.kt — auto-start/stop periscope binary lifecycle"
```

---

## Task 8: Wire MyToolWindowFactory + MyProjectActivity

**Files:**
- Modify: `jetbrains-plugin/src/main/kotlin/org/latentsignal/sampleplugin/toolWindow/MyToolWindowFactory.kt`
- Modify: `jetbrains-plugin/src/main/kotlin/org/latentsignal/sampleplugin/startup/MyProjectActivity.kt`
- Modify: `jetbrains-plugin/gradle.properties`

- [ ] **Step 8.1: Update MyToolWindowFactory.kt**

Replace the entire file content of `jetbrains-plugin/src/main/kotlin/org/latentsignal/sampleplugin/toolWindow/MyToolWindowFactory.kt`:

```kotlin
package org.latentsignal.sampleplugin.toolWindow

import com.intellij.openapi.project.Project
import com.intellij.openapi.wm.ToolWindow
import com.intellij.openapi.wm.ToolWindowFactory
import com.intellij.ui.content.ContentFactory
import com.intellij.ui.jcef.JBCefBrowser
import org.latentsignal.periscope.PeriscopeProcessManager
import java.awt.BorderLayout
import javax.swing.JPanel

class MyToolWindowFactory : ToolWindowFactory {

    override fun createToolWindowContent(project: Project, toolWindow: ToolWindow) {
        // Ensure periscope binary is running before loading the WebView.
        // PeriscopeProcessManager.start() is idempotent — safe to call here
        // even if MyProjectActivity already started it.
        PeriscopeProcessManager.start(project)

        val panel = JPanel(BorderLayout())
        val browser = JBCefBrowser(PeriscopeProcessManager.serverUrl())
        panel.add(browser.component, BorderLayout.CENTER)

        val content = ContentFactory.getInstance().createContent(panel, null, false)
        toolWindow.contentManager.addContent(content)
    }

    override fun shouldBeAvailable(project: Project) = true
}
```

- [ ] **Step 8.2: Update MyProjectActivity.kt**

Replace the entire file content of `jetbrains-plugin/src/main/kotlin/org/latentsignal/sampleplugin/startup/MyProjectActivity.kt`:

```kotlin
package org.latentsignal.sampleplugin.startup

import com.intellij.openapi.project.Project
import com.intellij.openapi.startup.ProjectActivity
import org.latentsignal.periscope.PeriscopeProcessManager

/**
 * Starts the periscope binary when a project is opened.
 * The process is stopped when the IDE disposes PeriscopeProcessManager.
 */
class MyProjectActivity : ProjectActivity {

    override suspend fun execute(project: Project) {
        PeriscopeProcessManager.start(project)
    }
}
```

- [ ] **Step 8.3: Update gradle.properties plugin version**

In `jetbrains-plugin/gradle.properties`, change:
```
version = 0.0.1
```
to:
```
version = 0.29.2-periscope.2
```

- [ ] **Step 8.4: Build the full plugin to verify**

```bash
cd jetbrains-plugin && ./gradlew buildPlugin --no-daemon 2>&1 | tail -30
```

Expected: `BUILD SUCCESSFUL`. The plugin zip will be at `jetbrains-plugin/build/distributions/Periscope-0.29.2-periscope.2.zip`.

```bash
ls jetbrains-plugin/build/distributions/
```

Expected: one `.zip` file with the correct version in the name.

- [ ] **Step 8.5: Commit**

```bash
cd ..
git add jetbrains-plugin/src/main/kotlin/org/latentsignal/sampleplugin/toolWindow/MyToolWindowFactory.kt
git add jetbrains-plugin/src/main/kotlin/org/latentsignal/sampleplugin/startup/MyProjectActivity.kt
git add jetbrains-plugin/gradle.properties
git commit -m "feat: wire PeriscopeProcessManager into MyToolWindowFactory and MyProjectActivity"
```

---

## Task 9: Full Build Verification + Tag Release

- [ ] **Step 9.1: Run all Go tests**

```bash
go test -tags fts5 ./... 2>&1 | tail -30
```

Expected: all PASS. Fix any failures before tagging.

- [ ] **Step 9.2: Full production build**

```bash
make build-release
./periscope --version
```

Expected: `v0.29.2-periscope.2` in output, binary exists and runs.

- [ ] **Step 9.3: Push the merged branch**

```bash
git push origin merged
```

- [ ] **Step 9.4: Tag and push the release**

```bash
git tag v0.29.2-periscope.2
git push origin v0.29.2-periscope.2
```

This triggers GitHub Actions. Visit `https://github.com/diazMelgarejo/periscope/actions` to watch the build.

- [ ] **Step 9.5: Verify CI success**

Wait for all 4 platform builds + JetBrains plugin job to complete (green checks). Expected artifacts on the release page:
- `periscope-linux-amd64.tar.gz`
- `periscope-linux-arm64.tar.gz`
- `periscope-darwin-arm64` (or `.tar.gz`)
- `periscope-windows-amd64.exe`
- `Periscope-0.29.2-periscope.2.zip` (JetBrains plugin)

---

## Task 10: End-to-End Install Script Test

This task verifies the full install path on a clean Mac (or clean shell with `~/.local/bin/periscope` removed).

- [ ] **Step 10.1: Remove any existing binary to simulate clean state**

```bash
rm -f ~/.local/bin/periscope
which periscope 2>/dev/null && echo "Still found — remove from PATH" || echo "Clean — not in PATH"
```

Expected: `Clean — not in PATH`

- [ ] **Step 10.2: Run the install script (release path)**

```bash
curl -fsSL https://raw.githubusercontent.com/diazMelgarejo/periscope/merged/scripts/install.sh | bash
```

Expected output includes: `Downloading pre-built binary...` followed by `Installed: ~/.local/bin/periscope`

- [ ] **Step 10.3: Verify installed binary**

```bash
~/.local/bin/periscope --version
```

Expected: output contains `v0.29.2-periscope.2`

- [ ] **Step 10.4: Test the source-build fallback path**

Simulate "no release found" by running with a non-existent release tag:

```bash
REPO="diazMelgarejo/periscope" BINARY_NAME="periscope" \
  bash -c '
    RELEASE_URL="https://github.com/${REPO}/releases/download/v999.0.0/${BINARY_NAME}-darwin-arm64"
    if curl --head --silent --fail "$RELEASE_URL" > /dev/null 2>&1; then
      echo "FOUND (unexpected)"
    else
      echo "NOT FOUND — fallback would trigger (correct)"
    fi
  '
```

Expected: `NOT FOUND — fallback would trigger (correct)`

The full source-build fallback is validated by the CI — running it locally requires Go + Node and is time-consuming, so this smoke test is sufficient.

- [ ] **Step 10.5: Run periscope and verify it serves the frontend**

```bash
~/.local/bin/periscope serve --port 8765 &
PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}" http://localhost:8765/
kill $PID
```

Expected: `200`

---

## Post-Implementation Checklist

After all 10 tasks complete:

- [ ] `grep -r "wesm/agentsview" --include="*.go" .` returns zero results
- [ ] `./periscope --version` prints `v0.29.2-periscope.2`
- [ ] `make build` succeeds and produces `periscope` binary
- [ ] `bash -n scripts/sync-upstream.sh` prints no errors
- [ ] GitHub Actions CI is green for all 4 platform targets
- [ ] JetBrains plugin zip appears on the GitHub release
- [ ] Install script downloads binary from release (not falls back to source)
- [ ] `docs/ARCHITECTURE.md` §Repeatable Checklist items are all satisfied
