#!/usr/bin/env bash
# ============================================================
# install.sh — Brewfile installer
# Usage:
#   ./install.sh              # base only
#   ./install.sh dev          # base + dev
#   ./install.sh work         # base + work
#   ./install.sh personal     # base + personal
#   ./install.sh all          # install everything
#   ./install.sh dev work     # multiple profiles
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILES_DIR="$SCRIPT_DIR/brewfiles"

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log()     { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }

# ── Homebrew check ──────────────────────────────────────────
ensure_brew() {
  if ! command -v brew &>/dev/null; then
    warn "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Apple Silicon path setup
    if [[ "$(uname -m)" == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    success "Homebrew installed successfully!"
  else
    success "Homebrew already installed ($(brew --version | head -1))"
  fi
}

# ── Install Brewfile ─────────────────────────────────────────
install_brewfile() {
  local name="$1"
  local file="$BREWFILES_DIR/${name}.Brewfile"

  if [[ ! -f "$file" ]]; then
    error "${name}.Brewfile not found: $file"
  fi

  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  log "📦 Installing ${name}.Brewfile..."
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

  brew bundle --file="$file" || warn "Some packages failed to install (continuing)"

  success "${name}.Brewfile done!"
}

# ── Main ─────────────────────────────────────────────────────
main() {
  echo ""
  echo -e "${BOLD}🍺 Dotfiles — Brew environment setup${RESET}"
  echo ""

  ensure_brew
  brew update

  # base is always installed
  install_brewfile "base"

  # parse arguments
  local profiles=("$@")

  if [[ ${#profiles[@]} -eq 0 ]]; then
    log "Installed base only. To install more: ./install.sh [dev|work|personal|all]"
    exit 0
  fi

  for profile in "${profiles[@]}"; do
    case "$profile" in
      all)
        install_brewfile "dev"
        install_brewfile "work"
        install_brewfile "personal"
        ;;
      dev|work|personal)
        install_brewfile "$profile"
        ;;
      *)
        error "Unknown profile: '$profile' (dev | work | personal | all)"
        ;;
    esac
  done

  echo ""
  echo -e "${GREEN}${BOLD}✅ All done!${RESET}"
  echo ""
}

main "$@"
