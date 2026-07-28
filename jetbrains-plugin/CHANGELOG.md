<!-- Keep a Changelog guide -> https://keepachangelog.com -->

# Periscope JetBrains Plugin Changelog

## [Unreleased]
### Changed
- Rebranded user-facing UI from AgentsView to Periscope (plugin name, tool window stripe,
  notifications, docs, and messages).
- `PeriscopeProcessManager` now prefers the `periscope` binary and falls back to legacy
  `agentsview`.
- Ready notification waits for `GET /api/v1/health` before reporting the server as ready.

### Added
- `PeriscopeProcessManager`: ref-counted singleton that starts the Periscope binary on project
  open and stops it when the last project closes. Auto-discovers a free port from 8080.
- `MyToolWindowFactory`: JCEF-based tool window wired to `PeriscopeProcessManager.serverUrl()`.
- `MyProjectActivity`: starts the process manager on project open; registers
  `ProjectManagerListener` to stop it on project close.
- Balloon notification group (legacy id `AgentsView`) — shown when server is ready or binary is missing.

### Removed
- IntelliJ template sample `MyProjectService`, rename/XML fixture tests, and unused bundle keys.
