#!/usr/bin/env bash
set -euo pipefail

# Simple dotfiles bootstrap for:
# - Neovim (nvim/)
# - Ghostty (ghostty/)
# - tmux   (tmux/)
#
# Run from the root of this repo:
#   chmod +x bootstrap.sh
#   ./bootstrap.sh

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.config"

backup_path() {
  local target="$1"

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    return 0
  fi

  # If it's already the correct symlink, skip
  if [ -L "$target" ]; then
    local current
    current="$(readlink "$target" || true)"
    if [ "$current" = "$2" ]; then
      echo "✔ $target already points to $2"
      return 0
    fi
  fi

  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"
  local backup="${target}.backup.${timestamp}"
  echo "⚠ Backing up existing $target -> $backup"
  mv "$target" "$backup"
}

link_config_dir() {
  local src_dir="$1"  # repo-relative (e.g., nvim, ghostty, tmux)
  local dest_dir="$2" # full path under ~/.config

  local src="${REPO_DIR}/${src_dir}"
  local dest="${dest_dir}"

  if [ ! -d "$src" ]; then
    echo "⏭ Skipping ${src_dir}: ${src} does not exist"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"

  backup_path "$dest" "$src"

  if [ ! -L "$dest" ]; then
    echo "🔗 Linking $dest -> $src"
    ln -s "$src" "$dest"
  fi
}

echo "==> Using repo at: $REPO_DIR"
mkdir -p "$CONFIG_DIR"

###############################################################################
# Neovim
###############################################################################
echo ""
echo "==> Setting up Neovim config"
link_config_dir "nvim" "${CONFIG_DIR}/nvim"

###############################################################################
# Ghostty
###############################################################################
echo ""
echo "==> Setting up Ghostty config"
link_config_dir "ghostty" "${CONFIG_DIR}/ghostty"

# On macOS, Ghostty can also use ~/Library/Application Support/com.mitchellh.ghostty
if [ "$(uname -s)" = "Darwin" ]; then
  echo "ℹ macOS detected."
  echo "  Ghostty prefers ~/.config/ghostty; if needed you can run:"
  echo "    defaults write com.mitchellh.ghostty ConfigPath -string \"$HOME/.config/ghostty\""
fi

###############################################################################
# tmux
###############################################################################
echo ""
echo "==> Setting up tmux config"
link_config_dir "tmux" "${CONFIG_DIR}/tmux"

TMUX_MAIN_CONF="${CONFIG_DIR}/tmux/tmux.conf"
TMUX_LEGACY_CONF="${HOME}/.tmux.conf"

if [ -f "$TMUX_MAIN_CONF" ] || [ -L "$TMUX_MAIN_CONF" ]; then
  echo "==> Ensuring legacy ~/.tmux.conf sources ~/.config/tmux/tmux.conf"

  # If ~/.tmux.conf exists and isn't the simple source line, back it up
  if [ -e "$TMUX_LEGACY_CONF" ] && ! grep -q 'source-file ~/.config/tmux/tmux.conf' "$TMUX_LEGACY_CONF" 2>/dev/null; then
    backup_path "$TMUX_LEGACY_CONF" "source-file ~/.config/tmux/tmux.conf"
  fi

  # Create or overwrite with a simple loader
  echo 'source-file ~/.config/tmux/tmux.conf' >"$TMUX_LEGACY_CONF"
  echo "🔗 Created loader $TMUX_LEGACY_CONF"
else
  echo "⏭ No ${TMUX_MAIN_CONF} found in repo yet; skipping loader."
fi

###############################################################################
# Final notes
###############################################################################
echo ""
echo "✅ Done."
echo "Configs now point to:"
echo "  Neovim : ${CONFIG_DIR}/nvim -> ${REPO_DIR}/nvim"
echo "  Ghostty: ${CONFIG_DIR}/ghostty -> ${REPO_DIR}/ghostty"
echo "  tmux   : ${CONFIG_DIR}/tmux -> ${REPO_DIR}/tmux"
echo ""
echo "If you open tmux now, it will load ~/.tmux.conf, which sources ~/.config/tmux/tmux.conf."
