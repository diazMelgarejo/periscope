#!/usr/bin/env bash
# Runs .cursor/cloud-agent-install.sh against a throwaway checkout.
# The installer's observable contract: repo path, persisted CGO, Node on PATH
# for a non-interactive shell, checksum rejection, and a pinned go install.
set -euo pipefail

script_src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/cloud-agent-install.sh"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

cleanup_root() {
  local root="$1"
  if [ -d "${root}" ]; then
    chmod -R u+w "${root}"
    rm -rf "${root}"
  fi
}

assert_eq() {
  local got="$1" want="$2" label="$3"
  if [ "${got}" != "${want}" ]; then
    printf 'FAIL: %s\n got: [%s]\n want: [%s]\n' "${label}" "${got}" "${want}" >&2
    exit 1
  fi
}

new_workspace() {
  local root="$1"
  mkdir -p \
    "${root}/home" \
    "${root}/repo/.cursor" \
    "${root}/repo/frontend" \
    "${root}/stubs" \
    "${root}/oldbin" \
    "${root}/prefix/usr/local/bin" \
    "${root}/tmp"
  cp "${script_src}" "${root}/repo/.cursor/cloud-agent-install.sh"
  chmod +x "${root}/repo/.cursor/cloud-agent-install.sh"

  cat > "${root}/oldbin/node" <<'EOF'
#!/bin/sh
echo v22.14.0
EOF
  chmod +x "${root}/oldbin/node"

  cat > "${root}/stubs/apt-get" <<'EOF'
#!/bin/sh
exit 0
EOF
  cat > "${root}/stubs/sudo" <<'EOF'
#!/bin/sh
echo "sudo is not used when PERISCOPE_CLOUD_PREFIX is set: $*" >&2
exit 99
EOF
  cat > "${root}/stubs/curl" <<'EOF'
#!/bin/bash
url=""
out=""
while [ $# -gt 0 ]; do
  case "$1" in
    -o)
      out="$2"
      shift 2
      ;;
    -*)
      shift
      ;;
    *)
      url="$1"
      shift
      ;;
  esac
done
printf '%s\n' "${url}" >> "${PERISCOPE_TEST_CURL_LOG}"
if [ -z "${PERISCOPE_TEST_FIXTURE_TARBALL:-}" ]; then
  echo "unexpected curl: ${url}" >&2
  exit 1
fi
if [ -z "${out}" ]; then
  echo "curl had no output file for ${url}" >&2
  exit 1
fi
cp "${PERISCOPE_TEST_FIXTURE_TARBALL}" "${out}"
EOF
  cat > "${root}/stubs/make" <<'EOF'
#!/bin/bash
here="$(pwd)"
printf '%s\n' "${here}" >> "${PERISCOPE_TEST_MAKE_LOG}"
if [ "${here}" != "${EXPECTED_REPO}" ]; then
  echo "make ran outside the checkout: ${here}" >&2
  exit 1
fi
mkdir -p .sqlite-include
printf 'header\n' > .sqlite-include/sqlite3.h
EOF
  cat > "${root}/stubs/go" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >> "${PERISCOPE_TEST_GO_LOG}"
if [ "${1:-}" = "env" ]; then
  exec /usr/bin/go "$@"
fi
if [ "${1:-}" = "install" ]; then
  dest="${GOBIN:?GOBIN is required}"
  mkdir -p "${dest}"
  cat > "${dest}/golangci-lint" <<'BIN'
#!/bin/sh
echo "golangci-lint has version 2.11.4 built with go1.26.0"
BIN
  chmod +x "${dest}/golangci-lint"
  exit 0
fi
if [ "${1:-}" = "mod" ] && [ "${2:-}" = "download" ]; then
  exit 0
fi
echo "unexpected go invocation: $*" >&2
exit 1
EOF
  chmod +x "${root}/stubs/"*
}

seed_node() {
  local bin="$1/prefix/usr/local/bin"
  cat > "${bin}/node" <<'EOF'
#!/bin/sh
echo v24.21.0
EOF
  cat > "${bin}/npm" <<'EOF'
#!/bin/sh
if [ "${1:-}" = "-v" ]; then
  echo 11.21.0
  exit 0
fi
echo "unexpected npm $*" >&2
exit 1
EOF
  printf '#!/bin/sh\nexit 0\n' > "${bin}/npx"
  printf '#!/bin/sh\nexit 0\n' > "${bin}/corepack"
  chmod +x "${bin}/node" "${bin}/npm" "${bin}/npx" "${bin}/corepack"
}

host_goroot="$(go env GOROOT)"

run_install() {
  local root="$1"
  env -i \
    HOME="${root}/home" \
    PATH="${root}/stubs:/usr/bin:/bin" \
    GOENV="${root}/goenv" \
    GOROOT="${host_goroot}" \
    GOTOOLCHAIN=local \
    TMPDIR="${root}/tmp" \
    PERISCOPE_CLOUD_PREFIX="${root}/prefix" \
    EXPECTED_REPO="${root}/repo" \
    PERISCOPE_TEST_GO_LOG="${root}/go.log" \
    PERISCOPE_TEST_CURL_LOG="${root}/curl.log" \
    PERISCOPE_TEST_MAKE_LOG="${root}/make.log" \
    PERISCOPE_TEST_FIXTURE_TARBALL="${PERISCOPE_TEST_FIXTURE_TARBALL:-}" \
    bash "${root}/repo/.cursor/cloud-agent-install.sh"
}

reject_bad_node_tarball() {
  local root fixture stage
  root="$(mktemp -d)"
  stage="$(mktemp -d)"
  new_workspace "${root}"
  mkdir -p "${stage}/node-v24.21.0-linux-x64/bin"
  printf '#!/bin/sh\necho v999\n' > "${stage}/node-v24.21.0-linux-x64/bin/node"
  chmod +x "${stage}/node-v24.21.0-linux-x64/bin/node"
  fixture="${root}/bad-node.tar.xz"
  tar -C "${stage}" -cJf "${fixture}" node-v24.21.0-linux-x64
  : > "${root}/curl.log"
  : > "${root}/go.log"
  : > "${root}/make.log"
  local status=0
  PERISCOPE_TEST_FIXTURE_TARBALL="${fixture}" run_install "${root}" || status=$?
  if [ "${status}" -eq 0 ]; then
    fail "untrusted node tarball was installed"
  fi
  assert_eq \
    "$(cat "${root}/curl.log")" \
    "https://nodejs.org/dist/v24.21.0/node-v24.21.0-linux-x64.tar.xz" \
    "node download url"
  if [ -x "${root}/prefix/usr/local/bin/node" ]; then
    local got
    got="$("${root}/prefix/usr/local/bin/node" -v 2>/dev/null || true)"
    if [ "${got}" = "v999" ]; then
      fail "checksum did not stop the untrusted node tarball"
    fi
  fi
  cleanup_root "${root}"
  cleanup_root "${stage}"
}

persist_when_header_exists() {
  local root repo include
  root="$(mktemp -d)"
  new_workspace "${root}"
  seed_node "${root}"
  repo="${root}/repo"
  include="${repo}/.sqlite-include"
  printf 'sqlite-vec-header:\npricing-snapshot:\n' > "${repo}/Makefile"
  : > "${root}/curl.log"
  : > "${root}/go.log"
  : > "${root}/make.log"
  run_install "${root}"
  run_install "${root}"

  assert_eq "$(cat "${root}/curl.log")" "" "curl must not run when node is current"
  assert_eq \
    "$(grep -c '^install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.11.4$' "${root}/go.log")" \
    "1" \
    "pinned golangci-lint install count"
  assert_eq "$(cat "${root}/make.log")" "$(printf '%s\n%s\n%s\n%s' "${repo}" "${repo}" "${repo}" "${repo}")" \
    "make directories"

  local source_count
  source_count="$(grep -cF "${root}/home/.config/periscope/cloud-agent-env.sh" "${root}/home/.bashrc")"
  assert_eq "${source_count}" "1" "bashrc sources the env file once"
  source_count="$(grep -cF "${root}/home/.config/periscope/cloud-agent-env.sh" "${root}/home/.profile")"
  assert_eq "${source_count}" "1" "profile sources the env file once"

  local shell_out
  shell_out="$(
    env -i \
      HOME="${root}/home" \
      PATH="${root}/oldbin:/usr/bin:/bin" \
      bash --noprofile --norc -c \
      ". \"${root}/prefix/etc/profile.d/periscope-cloud.sh\"; printf '%s\n%s\n' \"\$(node -v)\" \"\$CGO_CFLAGS\""
  )"
  assert_eq "${shell_out}" "$(printf 'v24.21.0\n-O2 -g -I%s' "${include}")" \
    "profile.d shell node and CGO_CFLAGS"

  shell_out="$(
    env -i \
      HOME="${root}/home" \
      PATH="${root}/oldbin:/usr/bin:/bin" \
      bash -lc "bash --noprofile --norc -c 'printf \"%s\n%s\n\" \"\$(node -v)\" \"\$CGO_CFLAGS\"'"
  )"
  assert_eq "${shell_out}" "$(printf 'v24.21.0\n-O2 -g -I%s' "${include}")" \
    "login shell child node and CGO_CFLAGS"

  shell_out="$(
    env -i \
      HOME="${root}/home" \
      GOENV="${root}/goenv" \
      GOROOT="${host_goroot}" \
      GOTOOLCHAIN=local \
      PATH="/usr/bin:/bin" \
      bash --noprofile --norc -c 'printf "%s\n%s\n" "$(go env CGO_CFLAGS)" "$(go env CGO_ENABLED)"'
  )"
  assert_eq "${shell_out}" "$(printf -- '-O2 -g -I%s\n1' "${include}")" \
    "go env CGO without shell startup"

  cleanup_root "${root}"
}

skip_cgo_when_header_absent() {
  local root out
  root="$(mktemp -d)"
  new_workspace "${root}"
  seed_node "${root}"
  printf 'all:\n\ttrue\n' > "${root}/repo/Makefile"
  : > "${root}/curl.log"
  : > "${root}/go.log"
  : > "${root}/make.log"
  run_install "${root}"
  assert_eq "$(cat "${root}/make.log")" "" "make stays idle without snapshot targets"
  out="$(
    env -i \
      HOME="${root}/home" \
      GOENV="${root}/goenv" \
      GOROOT="${host_goroot}" \
      GOTOOLCHAIN=local \
      PATH="/usr/bin:/bin" \
      bash --noprofile --norc -c 'go env CGO_CFLAGS; go env CGO_ENABLED'
  )"
  assert_eq "${out}" "$(printf -- '-O2 -g\n1')" \
    "go env CGO_CFLAGS without a bundled header"
  out="$(
    env -i \
      HOME="${root}/home" \
      PATH="${root}/oldbin:/usr/bin:/bin" \
      bash --noprofile --norc -c \
      ". \"${root}/prefix/etc/profile.d/periscope-cloud.sh\"; printf '%s' \"\${CGO_CFLAGS-unset}\""
  )"
  assert_eq "${out}" "unset" "shell CGO_CFLAGS without a bundled header"
  cleanup_root "${root}"
}

reject_bad_node_tarball
persist_when_header_exists
skip_cgo_when_header_absent
printf 'ok\n'
