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
  local desired="${2:-}"

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    return 0
  fi

  if [ -n "$desired" ] && [ -L "$target" ]; then
    local current
    current="$(readlink "$target" || true)"
    if [ "$current" = "$desired" ]; then
      echo "✔ $target already points to $desired"
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
# tmux
###############################################################################
echo ""
echo "==> Setting up tmux config"
TMUX_MAIN_CONF="${CONFIG_DIR}/tmux/tmux.conf"
TMUX_LEGACY_CONF="${HOME}/.tmux.conf"

# Link ~/.config/tmux -> repo/tmux
link_config_dir "tmux" "${CONFIG_DIR}/tmux"

# Ensure legacy ~/.tmux.conf loads the XDG config
if [ -f "$TMUX_MAIN_CONF" ] || [ -L "$TMUX_MAIN_CONF" ]; then
  echo "==> Ensuring legacy ~/.tmux.conf sources ~/.config/tmux/tmux.conf"

  if [ -e "$TMUX_LEGACY_CONF" ] && ! grep -q 'source-file ~/.config/tmux/tmux.conf' "$TMUX_LEGACY_CONF" 2>/dev/null; then
    backup_path "$TMUX_LEGACY_CONF" "source-file ~/.config/tmux/tmux.conf"
  fi

  echo 'source-file ~/.config/tmux/tmux.conf' >"$TMUX_LEGACY_CONF"
  echo "🔗 Created loader $TMUX_LEGACY_CONF"
else
  echo "⏭ No ${TMUX_MAIN_CONF} found yet; skipping legacy loader."
fi

###############################################################################
# Ghostty
###############################################################################
echo ""
echo "==> Setting up Ghostty config"
link_config_dir "ghostty" "${CONFIG_DIR}/ghostty"

GHOSTTY_CONF_REPO="${REPO_DIR}/ghostty/config"

# Point Ghostty at tmux with explicit config, and prefer zsh if available.
if [ -f "$GHOSTTY_CONF_REPO" ]; then
  TMUX_PATH="$(command -v tmux || true)"
  if [ -n "$TMUX_PATH" ]; then
    TMUX_CONF="${CONFIG_DIR}/tmux/tmux.conf"
    ZSH_PATH="$(command -v zsh || true)"

    if [ -e "$TMUX_CONF" ]; then
      if [ -n "$ZSH_PATH" ]; then
        echo "==> Updating Ghostty command to use zsh at: $ZSH_PATH and tmux at: $TMUX_PATH"
        NEW_CMD="command = SHELL=$ZSH_PATH $TMUX_PATH -f $TMUX_CONF"
      else
        echo "⚠ zsh not found; Ghostty will run tmux with its default shell."
        NEW_CMD="command = $TMUX_PATH -f $TMUX_CONF"
      fi
    else
      echo "⚠ tmux.conf not found at $TMUX_CONF; setting Ghostty to run plain tmux."
      if [ -n "$ZSH_PATH" ]; then
        NEW_CMD="command = SHELL=$ZSH_PATH $TMUX_PATH"
      else
        NEW_CMD="command = $TMUX_PATH"
      fi
    fi

    tmp_file="$(mktemp)"
    awk -v new_cmd="$NEW_CMD" '
      BEGIN { replaced = 0 }
      /^[[:space:]]*command[[:space:]]*=/ && !replaced {
        print new_cmd
        replaced = 1
        next
      }
      { print }
      END {
        if (!replaced) {
          print new_cmd
        }
      }
    ' "$GHOSTTY_CONF_REPO" >"$tmp_file"

    mv "$tmp_file" "$GHOSTTY_CONF_REPO"
    echo "✔ Ghostty config updated at $GHOSTTY_CONF_REPO"
  else
    echo "⚠ tmux not found on PATH; skipping Ghostty command update."
  fi
else
  echo "⏭ No Ghostty config file found at $GHOSTTY_CONF_REPO; skipping command update."
fi

# On macOS, Ghostty can also use ~/Library/Application Support/com.mitchellh.ghostty
if [ "$(uname -s)" = "Darwin" ]; then
  echo "ℹ macOS detected."
  echo "  Ghostty prefers ~/.config/ghostty; if needed you can run:"
  echo "    defaults write com.mitchellh.ghostty ConfigPath -string \"$HOME/.config/ghostty\""
fi

###############################################################################
# Final notes
###############################################################################
echo ""
echo "✅ Done."
echo "Configs now point to:"
echo "  Neovim : ${CONFIG_DIR}/nvim -> ${REPO_DIR}/nvim"
echo "  tmux   : ${CONFIG_DIR}/tmux -> ${REPO_DIR}/tmux"
echo "  Ghostty: ${CONFIG_DIR}/ghostty -> ${REPO_DIR}/ghostty"
echo ""
echo "If a tmux server was already running, you may want to run:"
echo "  tmux kill-server"
echo "then restart Ghostty so tmux picks up the new default shell (zsh)."
