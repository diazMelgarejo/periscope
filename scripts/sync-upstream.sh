#!/usr/bin/env bash
# sync-upstream.sh — diazMelgarejo/periscope upstream synchronization helper
#
# Canonical policy: docs/guides/periscope-upstream-sync-blueprint.md
# Architecture / invariants: docs/ARCHITECTURE.md
#
# Usage:
#   ./scripts/sync-upstream.sh --dry-run [--source latentsignal|kenn]
#   ./scripts/sync-upstream.sh --simulate [--source latentsignal|kenn]
#   ./scripts/sync-upstream.sh [--source latentsignal|kenn] [--non-interactive]
#   ./scripts/sync-upstream.sh --refresh-mirror <agentsview|main> \
#       --authorize-remote-update --lease-sha <sha>
#
# Safety:
#   - Never pushes to remotes
#   - Never force-updates without --authorize-remote-update and --lease-sha
#   - --dry-run and --simulate are non-interactive
#   - Default merge stops on unknown conflicts unless a TTY prompt is available
#     (use --non-interactive to fail fast in CI)

set -euo pipefail

KENN_URL="https://github.com/kenn-io/agentsview.git"
LATENTSIGNAL_URL="https://github.com/latentsignal-org/periscope.git"
FORK_REMOTE="${FORK_REMOTE:-origin}"

SOURCE="latentsignal"
DRY_RUN=0
SIMULATE=0
NON_INTERACTIVE=0
AUTHORIZE_REMOTE=0
LEASE_SHA=""
REFRESH_MIRROR=""
UPSTREAM_REF="${UPSTREAM_REF:-main}"

PERISCOPE_OWNED=(
    "internal/summarize"
    "internal/llm"
    "internal/guidance"
    "frontend/src/lib/components/context"
    "frontend/src/lib/components/content/SessionVitals.svelte"
    "frontend/src/lib/components/content/ActivityLane.svelte"
    "jetbrains-plugin"
    "scripts/install.sh"
    "scripts/sync-upstream.sh"
    "docs/ARCHITECTURE.md"
    "docs/guides/periscope-upstream-sync-blueprint.md"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[sync]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }
step()  { echo -e "${CYAN}==> $*${NC}"; }

verify_invariants() {
    step "Verifying periscope invariants"
    local failures=0

    check_exists() {
        local path="$1" label="${2:-$1}"
        if [[ -e "$path" ]]; then
            info "  ✓ $label"
        else
            warn "  ✗ MISSING: $label"
            failures=$((failures + 1))
        fi
    }

    check_exists "internal/summarize" "summarizer package"
    check_exists "internal/llm" "LLM package"
    check_exists "frontend/src/lib/components/context/ContextPage.svelte" "ContextPage"
    check_exists "frontend/src/lib/components/content/SessionVitals.svelte" "SessionVitals"
    check_exists "frontend/src/lib/components/content/ActivityLane.svelte" "ActivityLane"
    check_exists "jetbrains-plugin" "JetBrains plugin"

    if [[ $failures -gt 0 && "$DRY_RUN" != "1" && "$SIMULATE" != "1" ]]; then
        error "$failures invariant(s) missing after merge"
    elif [[ $failures -gt 0 ]]; then
        warn "$failures invariant check(s) failed (reporting only)"
    fi
}

usage() {
    sed -n '2,20p' "$0" | sed 's/^# //'
    exit 0
}

upstream_url() {
    case "$SOURCE" in
        kenn) echo "$KENN_URL" ;;
        latentsignal) echo "$LATENTSIGNAL_URL" ;;
        *) error "Unknown --source: $SOURCE (expected kenn or latentsignal)" ;;
    esac
}

upstream_remote_name() {
    case "$SOURCE" in
        kenn) echo "upstream-kenn" ;;
        latentsignal) echo "upstream-latentsignal" ;;
    esac
}

mirror_branch_for_source() {
    case "$SOURCE" in
        kenn) echo "agentsview" ;;
        latentsignal) echo "main" ;;
    esac
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift ;;
        --simulate) SIMULATE=1; shift ;;
        --non-interactive) NON_INTERACTIVE=1; shift ;;
        --source) SOURCE="$2"; shift 2 ;;
        --upstream-ref) UPSTREAM_REF="$2"; shift 2 ;;
        --authorize-remote-update) AUTHORIZE_REMOTE=1; shift ;;
        --lease-sha) LEASE_SHA="$2"; shift 2 ;;
        --refresh-mirror) REFRESH_MIRROR="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) error "Unknown option: $1" ;;
    esac
done

if [[ "$DRY_RUN" == "1" && "$SIMULATE" == "1" ]]; then
    error "Choose only one of --dry-run or --simulate"
fi

if [[ -n "$REFRESH_MIRROR" ]]; then
  case "$REFRESH_MIRROR" in
    agentsview) SOURCE="kenn" ;;
    main) SOURCE="latentsignal" ;;
    *) error "--refresh-mirror must be agentsview or main" ;;
  esac
  if [[ "$AUTHORIZE_REMOTE" != "1" || -z "$LEASE_SHA" ]]; then
    error "--refresh-mirror requires --authorize-remote-update and --lease-sha <sha>"
  fi
  step "Mirror refresh proposal for ${FORK_REMOTE}/${REFRESH_MIRROR}"
  REMOTE_NAME="$(upstream_remote_name)"
  URL="$(upstream_url)"
  if ! git remote get-url "$REMOTE_NAME" &>/dev/null; then
    git remote add "$REMOTE_NAME" "$URL"
  fi
  git fetch "$REMOTE_NAME" "$UPSTREAM_REF"
  UPSTREAM_TREE="$(git rev-parse "${REMOTE_NAME}/${UPSTREAM_REF}^{tree}")"
  CURRENT_SHA="$(git rev-parse "${FORK_REMOTE}/${REFRESH_MIRROR}" 2>/dev/null || echo "")"
  info "Current ${FORK_REMOTE}/${REFRESH_MIRROR}: ${CURRENT_SHA:-<missing>}"
  info "Lease SHA: ${LEASE_SHA}"
  info "Upstream tree: ${UPSTREAM_TREE:0:12}"
  if [[ -n "$CURRENT_SHA" && "$CURRENT_SHA" != "$LEASE_SHA" ]]; then
    error "Lease SHA does not match ${FORK_REMOTE}/${REFRESH_MIRROR} (${CURRENT_SHA:0:12})"
  fi
  info "Would tag backup: backup/pre-refresh-${REFRESH_MIRROR}-$(date -u +%Y%m%dT%H%M%SZ)"
  info "Would update ${FORK_REMOTE}/${REFRESH_MIRROR} to ${REMOTE_NAME}/${UPSTREAM_REF} with --force-with-lease=${LEASE_SHA}"
  warn "No remote mutation performed — operator must run the proposed commands manually."
  exit 0
fi

REMOTE_NAME="$(upstream_remote_name)"
URL="$(upstream_url)"
MIRROR_BRANCH="$(mirror_branch_for_source)"

step "Checking git state"
if [[ -n "$(git status --porcelain)" ]]; then
    error "Working tree is dirty. Commit or stash changes before syncing."
fi

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
info "Current branch: $CURRENT_BRANCH"
info "Upstream source: $SOURCE ($URL)"

step "Fetching ${REMOTE_NAME}/${UPSTREAM_REF}"
if ! git remote get-url "$REMOTE_NAME" &>/dev/null; then
    info "Adding remote ${REMOTE_NAME}..."
    git remote add "$REMOTE_NAME" "$URL"
fi
git fetch "$REMOTE_NAME" "$UPSTREAM_REF" --tags

UPSTREAM_COMMIT="$(git rev-parse "${REMOTE_NAME}/${UPSTREAM_REF}")"
info "Upstream at ${UPSTREAM_COMMIT:0:12}"

if [[ "$DRY_RUN" == "1" ]]; then
    step "Dry-run summary"
    info "Would merge ${REMOTE_NAME}/${UPSTREAM_REF} into ${CURRENT_BRANCH}"
    echo
    git log --oneline "HEAD..${REMOTE_NAME}/${UPSTREAM_REF}" | head -30 || true
    echo
    info "Mirror branch ${MIRROR_BRANCH} should remain tree-identical to ${REMOTE_NAME}/${UPSTREAM_REF}"
    if git show-ref --verify --quiet "refs/remotes/${FORK_REMOTE}/${MIRROR_BRANCH}"; then
        if git diff --quiet "${FORK_REMOTE}/${MIRROR_BRANCH}" "${REMOTE_NAME}/${UPSTREAM_REF}"; then
            info "  ✓ ${FORK_REMOTE}/${MIRROR_BRANCH} matches upstream tree"
        else
            warn "  ✗ ${FORK_REMOTE}/${MIRROR_BRANCH} differs from ${REMOTE_NAME}/${UPSTREAM_REF}"
        fi
    else
        warn "  ? ${FORK_REMOTE}/${MIRROR_BRANCH} not present locally"
    fi
    verify_invariants
    warn "[dry-run] No changes made."
    exit 0
fi

if [[ "$SIMULATE" == "1" ]]; then
    step "Simulating merge in disposable worktree"
    WORKTREE="$(mktemp -d)"
    trap 'git worktree remove --force "$WORKTREE" 2>/dev/null || rm -rf "$WORKTREE"' EXIT
    git worktree add -B "sync-sim-$(date +%s)" "$WORKTREE" HEAD >/dev/null
  (
    cd "$WORKTREE"
    if git merge --no-commit --no-ff "${REMOTE_NAME}/${UPSTREAM_REF}"; then
        info "Simulated merge: clean (no conflicts)"
    else
        warn "Simulated merge: conflicts detected"
        git diff --name-only --diff-filter=U || true
        git merge --abort || true
    fi
  )
    verify_invariants
    warn "[simulate] Worktree removed; branch unchanged."
    exit 0
fi

step "Merging ${REMOTE_NAME}/${UPSTREAM_REF}"
if git merge --no-ff "${REMOTE_NAME}/${UPSTREAM_REF}" \
        -m "chore: merge upstream ${SOURCE} @ ${UPSTREAM_COMMIT:0:12}"; then
    info "Merge succeeded with no conflicts."
else
    info "Merge has conflicts — applying periscope-owned auto-resolution..."
    for owned in "${PERISCOPE_OWNED[@]}"; do
        if git diff --name-only --diff-filter=U | grep -q "^${owned}"; then
            info "Auto-keeping ours for: ${owned}"
            git checkout --ours -- "${owned}" 2>/dev/null || true
            git add "${owned}" 2>/dev/null || true
        fi
    done

    REMAINING="$(git diff --name-only --diff-filter=U 2>/dev/null || true)"
    if [[ -n "$REMAINING" ]]; then
        warn "Remaining conflicts:"
        echo "$REMAINING" | sed 's/^/  - /'
        if [[ "$NON_INTERACTIVE" == "1" || ! -t 0 ]]; then
            error "Unresolved conflicts (non-interactive). Abort with: git merge --abort"
        fi
        echo
        read -rp "Open a shell to resolve conflicts now? [y/N] " answer
        if [[ "${answer,,}" == "y" ]]; then
            bash --rcfile <(echo 'PS1="[merge-shell] \w \$ "') || true
        else
            warn "Merge left in progress. Resolve manually: git merge --continue"
            exit 1
        fi
        STILL="$(git diff --name-only --diff-filter=U 2>/dev/null || true)"
        if [[ -n "$STILL" ]]; then
            error "Conflicts remain:\n$STILL"
        fi
    fi
    git merge --continue --no-edit
fi

verify_invariants

echo
info "Merge complete. Upstream ${UPSTREAM_COMMIT:0:12} integrated into ${CURRENT_BRANCH}."
info "Run: go test -tags fts5 ./... && make build"
warn "This script never pushes. Review locally before any remote update."
