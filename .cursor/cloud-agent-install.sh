#!/usr/bin/env bash
# Idempotent Cloud Agent install for periscope.
# Dependency and toolchain setup only; no servers and no tests.
set -euo pipefail

NODE_VERSION=24.21.0
NPM_VERSION=11.21.0
GCL_VERSION=v2.11.4

export PATH="${HOME}/.local/bin:${PATH}"
export CGO_ENABLED=1
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  git \
  pkg-config \
  libsqlite3-dev \
  xz-utils

mkdir -p "${HOME}/go/pkg/mod" "${HOME}/.cache/go-build" "${HOME}/.local/bin"
if [ ! -w "${HOME}/go" ] || [ ! -w "${HOME}/go/pkg/mod" ] || [ ! -w "${HOME}/.cache/go-build" ]; then
  sudo chown -R "$(id -u):$(id -g)" "${HOME}/go" "${HOME}/.cache/go-build"
fi

if ! "${HOME}/.local/bin/node" -v 2>/dev/null | grep -qx "v${NODE_VERSION}"; then
  tmp="$(mktemp -d)"
  curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
    -o "${tmp}/node.tar.xz"
  sudo tar -xJf "${tmp}/node.tar.xz" -C /usr/local --strip-components=1 --no-same-owner
  rm -rf "${tmp}"
fi
for cmd in node npm npx corepack; do
  ln -sfn "/usr/local/bin/${cmd}" "${HOME}/.local/bin/${cmd}"
done

# Login and agent shells source ~/.bashrc. Prepend the supported Node so it
# wins over the older /exec-daemon/node (v22.14.0), which is outside the
# frontend engines range.
path_line='export PATH="$HOME/.local/bin:$PATH"'
if ! grep -qxF "${path_line}" "${HOME}/.bashrc"; then
  printf '\n%s\n' "${path_line}" >> "${HOME}/.bashrc"
fi

# Node 24.21.0 ships npm 11.19.0. Stay on the last npm 11 release. npm 12 is
# not bundled until Node 27 and blocks install scripts and git dependencies.
if ! "${HOME}/.local/bin/npm" -v 2>/dev/null | grep -qx "${NPM_VERSION}"; then
  sudo env PATH="/usr/local/bin:${PATH}" npm install -g "npm@${NPM_VERSION}"
fi
for cmd in npm npx; do
  ln -sfn "/usr/local/bin/${cmd}" "${HOME}/.local/bin/${cmd}"
done

if ! command -v golangci-lint >/dev/null 2>&1 || ! golangci-lint version 2>/dev/null | grep -q '2\.11\.4'; then
  tmp="$(mktemp -d)"
  curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh \
    | sh -s -- -b "${tmp}" "${GCL_VERSION}"
  sudo install -m 0755 "${tmp}/golangci-lint" /usr/local/bin/golangci-lint
  rm -rf "${tmp}"
fi
ln -sfn /usr/local/bin/golangci-lint "${HOME}/.local/bin/golangci-lint"

cd /workspace
go mod download
# merged stages a bundled SQLite header and pricing snapshot. main does not
# define those targets, and environment builds check out the default branch.
if grep -q '^sqlite-vec-header:' Makefile; then
  make sqlite-vec-header
fi
if grep -q '^pricing-snapshot:' Makefile; then
  make pricing-snapshot
fi

# When the bundled header exists, persist the same CGO_CFLAGS make uses so
# plain go test/build compile sqlite-vec against that header. libsqlite3-dev
# remains the fallback on branches that do not stage the header.
sqlite_include="/workspace/.sqlite-include"
if [ -f "${sqlite_include}/sqlite3.h" ]; then
  sudo tee /etc/profile.d/periscope-cgo.sh >/dev/null <<EOF
# Bundled SQLite header for sqlite-vec. Mirrors the Makefile CGO_CFLAGS.
case "\${CGO_CFLAGS:-}" in
  *-I${sqlite_include}*) ;;
  *) export CGO_CFLAGS="-O2 -g -I${sqlite_include}\${CGO_CFLAGS:+ \$CGO_CFLAGS}" ;;
esac
export CGO_ENABLED=1
EOF
  marker="# periscope-cgo-sqlite-include"
  if ! grep -q "${marker}" "${HOME}/.bashrc"; then
    cat >> "${HOME}/.bashrc" <<EOF

${marker}
case "\${CGO_CFLAGS:-}" in
  *-I${sqlite_include}*) ;;
  *) export CGO_CFLAGS="-O2 -g -I${sqlite_include}\${CGO_CFLAGS:+ \$CGO_CFLAGS}" ;;
esac
export CGO_ENABLED=1
EOF
  fi
fi

if [ -f frontend/package-lock.json ]; then
  cd /workspace/frontend
  npm ci
fi
