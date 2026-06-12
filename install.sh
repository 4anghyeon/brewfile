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
  local interactive="${2:-false}"

  if [[ ! -f "$file" ]]; then
    error "${name}.Brewfile not found: $file"
  fi

  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  log "📦 Installing ${name}.Brewfile..."
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

  if [[ "$interactive" == "true" ]]; then
    install_brewfile_interactive "$name" "$file"
  else
    brew bundle --file="$file" --verbose || warn "Some packages failed to install (continuing)"
    success "${name}.Brewfile done!"
  fi
}

# ── Interactive install (ask per item) ───────────────────────
install_brewfile_interactive() {
  local name="$1"
  local file="$2"
  local tmp_file
  tmp_file="$(mktemp /tmp/Brewfile.XXXXXX)"

  echo ""
  log "항목을 하나씩 확인합니다. 설치할 항목에 y를 입력하세요."
  echo ""

  local current_comment=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    # 빈 줄 — 섹션 구분자이므로 주석 초기화
    if [[ -z "$line" ]]; then
      current_comment=""
      continue
    fi

    # 주석 라인 — 섹션 헤더로 저장
    if [[ "$line" =~ ^[[:space:]]*# ]]; then
      current_comment="${line#*#}"
      current_comment="${current_comment## }"
      continue
    fi

    # brew / cask / tap 라인만 처리
    if [[ "$line" =~ ^[[:space:]]*(brew|cask|tap)[[:space:]] ]]; then
      # 패키지 이름 추출 (첫 번째 따옴표 안의 값)
      local pkg
      pkg="$(echo "$line" | grep -oE '"[^"]+"' | head -1 | tr -d '"')" || true

      # 인라인 주석 추출
      local inline_desc=""
      if [[ "$line" =~ \#[[:space:]]*(.+)$ ]]; then
        inline_desc="${BASH_REMATCH[1]}"
      fi

      # 사용자에게 표시할 설명
      local desc="${inline_desc:-${current_comment}}"
      if [[ -n "$desc" ]]; then
        printf "  ${CYAN}%-40s${RESET} %s\n" "$pkg" "$desc"
      else
        printf "  ${CYAN}%s${RESET}\n" "$pkg"
      fi

      printf "  설치하시겠습니까? [Y/n] "
      local answer
      read -r answer </dev/tty || true
      if [[ -z "$answer" || "$answer" == " " || "$answer" =~ ^[Yy]$ ]]; then
        echo "$line" >> "$tmp_file"
        success "  → 선택됨: $pkg"
      else
        warn "  → 건너뜀: $pkg"
      fi
      echo ""
    fi
  done < "$file"

  if [[ ! -s "$tmp_file" ]]; then
    warn "선택된 항목이 없습니다. ${name}.Brewfile 건너뜀."
    rm -f "$tmp_file"
    return
  fi

  echo ""
  log "선택한 항목을 설치합니다..."
  brew bundle --file="$tmp_file" --verbose || warn "일부 패키지 설치에 실패했습니다 (계속 진행)"
  rm -f "$tmp_file"

  success "${name}.Brewfile done!"
}

# ── Main ─────────────────────────────────────────────────────
main() {
  echo ""
  echo -e "${BOLD}🍺 Dotfiles — Brew environment setup${RESET}"
  echo ""

  ensure_brew
  brew update || warn "brew update failed, continuing"

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
        install_brewfile "dev" "true"
        install_brewfile "personal" "true"
        ;;
      dev|personal)
        install_brewfile "$profile" "true"
        ;;
      work)
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
