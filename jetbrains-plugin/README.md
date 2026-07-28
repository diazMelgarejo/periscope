# AgentsView — JetBrains Plugin

Embedded session viewer for the [AgentsView](https://github.com/latentsignal-org/periscope) local AI-agent session database.

<!-- Plugin description -->
**AgentsView** embeds a full session-history viewer directly inside your IDE.

- Launches the `agentsview` binary automatically when a project opens and shuts it down when it closes.
- Displays the AgentsView web UI in a dedicated **AgentsView** tool window (right sidebar) via JCEF.
- Auto-discovers a free port starting at 8080 — no port conflicts, no manual setup.
- Shows a balloon notification when the server is ready or if the binary cannot be found.

Requires the `agentsview` binary on `PATH` or installed in `~/.local/bin`, `~/bin`, or `/usr/local/bin`.
Legacy `periscope` binary names are also accepted.
<!-- Plugin description end -->

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
- `agentsview` binary installed and on `PATH`

## Installation

Download `jetbrains-plugin-*.zip` from a release and install via
<kbd>Settings</kbd> > <kbd>Plugins</kbd> > <kbd>⚙️</kbd> > <kbd>Install plugin from disk...</kbd>
