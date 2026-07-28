# Periscope — JetBrains Plugin

Embedded session viewer for [Periscope](https://github.com/latentsignal-org/periscope), the local AI-agent session database.

<!-- Plugin description -->
**Periscope** embeds a full session-history viewer directly inside your IDE.

- Launches the `periscope` binary automatically when a project opens and shuts it down when it closes.
- Displays the Periscope web UI in a dedicated **Periscope** tool window (right sidebar) via JCEF.
- Auto-discovers a free port starting at 8080 — no port conflicts, no manual setup.
- Waits for the server health endpoint before showing a ready notification.

Requires the `periscope` binary on `PATH` or installed in `~/.local/bin`, `~/bin`, or `/usr/local/bin`.
Legacy `agentsview` binary names are accepted as a fallback.
<!-- Plugin description end -->

## Plugin identity

| Field | Value | Notes |
|-------|-------|-------|
| Plugin ID | `org.latentsignal.periscope` | Unchanged — preserves Marketplace update continuity |
| Tool window ID | `AgentsView` | Legacy internal ID; stripe label shows **Periscope** |
| Notification group ID | `AgentsView` | Legacy internal ID; display name shows **Periscope** |

## Development

```bash
cd jetbrains-plugin
./gradlew build       # compile and package the plugin
./gradlew runIde      # launch a sandboxed IDE with the plugin loaded
./gradlew buildPlugin # produce distributable ZIP in build/distributions/
```

## Requirements

- IntelliJ IDEA 2025.1 or later (Community or Ultimate)
- JDK 21+
- `periscope` binary installed and on `PATH` (or legacy `agentsview`)

## Installation

Download `jetbrains-plugin-*.zip` from a release and install via
<kbd>Settings</kbd> > <kbd>Plugins</kbd> > <kbd>⚙️</kbd> > <kbd>Install plugin from disk...</kbd>
