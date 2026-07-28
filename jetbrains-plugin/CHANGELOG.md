<!-- Keep a Changelog guide -> https://keepachangelog.com -->

# AgentsView JetBrains Plugin Changelog

## [Unreleased]
### Added
- `PeriscopeProcessManager`: ref-counted singleton that starts the `agentsview` binary on project
  open and stops it when the last project closes. Auto-discovers a free port from 8080.
- `MyToolWindowFactory`: JCEF-based tool window wired to `PeriscopeProcessManager.serverUrl()`.
- `MyProjectActivity`: starts the process manager on project open; registers
  `ProjectManagerListener` to stop it on project close.
- Balloon notification group `AgentsView` — shown when server is ready or binary is missing.

### Removed
- IntelliJ template sample `MyProjectService`, rename/XML fixture tests, and unused bundle keys.
