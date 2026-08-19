#!/usr/bin/env bash
set -euo pipefail

APP="nex"
REPO="besmart12349/NexCLI"
RELEASES_API="https://api.github.com/repos/${REPO}/releases"
USER_DIR="${HOME}/.nex"
INSTALL_DIR="${USER_DIR}/bin"
SRC_DIR="${USER_DIR}/src"
METADATA_PATH="${USER_DIR}/install.json"
PATH_MARKER="# nex"

no_modify_path=false
requested_version=""

usage() {
  cat <<EOF
NexCLI installer

Usage:
  curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | bash -s -- --version v1.1.7
  curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | bash -s -- --no-modify-path
EOF
}

log() { printf '%s\n' "$*"; }
err() { printf '%s\n' "$*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      requested_version="${2:-}"
      shift 2
      ;;
    --no-modify-path)
      no_modify_path=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      err "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

detect_platform() {
  local raw_os arch
  raw_os=$(uname -s)
  case "$raw_os" in
    Darwin) OS="darwin" ;;
    Linux) OS="linux" ;;
    MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
    *)
      err "Unsupported OS: ${raw_os}"
      exit 1
      ;;
  esac

  arch=$(uname -m)
  case "$arch" in
    arm64|aarch64) ARCH="arm64" ;;
    x86_64|amd64) ARCH="x64" ;;
    *)
      err "Unsupported architecture: ${arch}"
      exit 1
      ;;
  esac

  TARGET="${OS}-${ARCH}"
  case "$TARGET" in
    darwin-arm64|darwin-x64|linux-x64|linux-arm64|windows-x64) ;;
    *)
      err "Unsupported platform: ${TARGET}"
      exit 1
      ;;
  esac
}

warn_macos_version() {
  [[ "$OS" == "darwin" ]] || return 0
  local major
  major=$(sw_vers -productVersion 2>/dev/null | cut -d. -f1 || echo 0)
  if [[ "${major:-0}" -lt 13 ]]; then
    err "Warning: NexCLI depends on Bun, which requires macOS 13.0 or later."
    err "This Mac reports $(sw_vers -productVersion 2>/dev/null || echo unknown). Upgrade macOS before installing if the installer fails."
  fi
}

ensure_dirs() {
  mkdir -p "$INSTALL_DIR" "$USER_DIR"
  chmod 700 "$USER_DIR" 2>/dev/null || true
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

ensure_bun() {
  if need_cmd bun; then
    return 0
  fi
  log "Bun not found. Installing Bun..."
  curl -fsSL https://bun.com/install | bash
  # shellcheck disable=SC1090
  [[ -f "${HOME}/.bun/bin/bun" ]] && export PATH="${HOME}/.bun/bin:${PATH}"
  if ! need_cmd bun; then
    err "Bun install finished but bun is not on PATH. Open a new terminal and retry."
    exit 1
  fi
}

write_metadata() {
  local method="$1" version="$2"
  cat > "$METADATA_PATH" <<EOF
{
  "app": "${APP}",
  "repo": "${REPO}",
  "target": "${TARGET}",
  "method": "${method}",
  "version": "${version}",
  "installDir": "${INSTALL_DIR}"
}
EOF
}

install_wrapper() {
  local target_js="$1"
  cat > "${INSTALL_DIR}/${APP}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.bun/bin:\${PATH}"
if command -v bun >/dev/null 2>&1; then
  exec bun "${target_js}" "\$@"
fi
exec node "${target_js}" "\$@"
EOF
  chmod +x "${INSTALL_DIR}/${APP}"
}

download_release_binary() {
  local asset_name="${APP}-${TARGET}"
  [[ "$OS" == "windows" ]] && asset_name="${asset_name}.exe"
  local dest="${INSTALL_DIR}/${APP}"
  [[ "$OS" == "windows" ]] && dest="${dest}.exe"

  local api_url
  if [[ -n "$requested_version" ]]; then
    api_url="${RELEASES_API}/tags/${requested_version}"
  else
    api_url="${RELEASES_API}/latest"
  fi

  local json
  if ! json=$(curl -fsSL -H "Accept: application/vnd.github+json" "$api_url" 2>/dev/null); then
    return 1
  fi

  local download_url
  download_url=$(printf '%s' "$json" | sed -n "s/.*\"browser_download_url\": \"\([^\"]*${asset_name}\)\".*/\1/p" | head -n 1)
  [[ -n "$download_url" ]] || return 1

  log "Downloading ${asset_name}..."
  curl -fL --progress-bar "$download_url" -o "$dest"
  chmod +x "$dest"
  local version
  version=$(printf '%s' "$json" | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -n 1)
  write_metadata "release" "${version:-unknown}"
  return 0
}

install_from_source() {
  ensure_bun
  if ! need_cmd git; then
    err "git is required to build NexCLI from source."
    exit 1
  fi

  log "No ${TARGET} release binary found. Building NexCLI from source..."
  rm -rf "$SRC_DIR"
  git clone --depth 1 "https://github.com/${REPO}.git" "$SRC_DIR"
  (
    cd "$SRC_DIR"
    bun install
    bun run build
  )
  if [[ ! -f "${SRC_DIR}/dist/index.js" ]]; then
    err "Build finished but dist/index.js is missing."
    exit 1
  fi
  install_wrapper "${SRC_DIR}/dist/index.js"
  write_metadata "source" "main"
}

maybe_update_path() {
  if [[ "$no_modify_path" == true ]]; then
    return
  fi
  local command="export PATH=\"${INSTALL_DIR}:\$PATH\""
  local config_file=""
  if [[ -n "${ZDOTDIR:-}" && -f "${ZDOTDIR}/.zshrc" ]]; then
    config_file="${ZDOTDIR}/.zshrc"
  elif [[ -f "${HOME}/.zshrc" ]]; then
    config_file="${HOME}/.zshrc"
  elif [[ -f "${HOME}/.bashrc" ]]; then
    config_file="${HOME}/.bashrc"
  elif [[ -f "${HOME}/.bash_profile" ]]; then
    config_file="${HOME}/.bash_profile"
  elif [[ -f "${HOME}/.profile" ]]; then
    config_file="${HOME}/.profile"
  fi

  if [[ -z "$config_file" ]]; then
    err "Could not find a shell config file. Add this to your PATH:"
    err "  ${command}"
    return
  fi

  if grep -Fq "$PATH_MARKER" "$config_file" 2>/dev/null; then
    return
  fi

  printf '\n%s\n%s\n' "$PATH_MARKER" "$command" >> "$config_file"
  log "Added ${INSTALL_DIR} to PATH in ${config_file}"
}

main() {
  detect_platform
  warn_macos_version
  ensure_dirs
  log "Installing NexCLI for ${TARGET}..."

  if download_release_binary; then
    log "Installed release binary to ${INSTALL_DIR}/${APP}"
  else
    install_from_source
    log "Installed source build wrapper to ${INSTALL_DIR}/${APP}"
  fi

  maybe_update_path
  log "Done. Open a new terminal and run: ${APP}"
  log "Set NEX_API_KEY before the first run."
}

main
