# Dotfiles

Personal configuration files for Neovim, tmux, and Ghostty terminal.

## Quick Start

```bash
git clone <this-repo> ~/ghostty-config-dotfiles
cd ~/ghostty-config-dotfiles
chmod +x bootstrap.sh
./bootstrap.sh
```

The bootstrap script will symlink configs to `~/.config/` and set up Ghostty to launch tmux with zsh.

## Post-Install: TPM (Tmux Plugin Manager)

The tmux config uses TPM for plugin management. Install it with:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then inside tmux, press `prefix + I` (capital I) to install plugins.

### Included tmux plugins

- **tmux-resurrect** - Save and restore sessions (`prefix + Ctrl-s` / `prefix + Ctrl-r`)
- **tmux-continuum** - Auto-save every 15 minutes, auto-restore on tmux start

## Structure

```
├── bootstrap.sh     # Setup script
├── ghostty/         # Ghostty terminal config
├── nvim/            # Neovim config
└── tmux/            # tmux config
```

## Notes

- If tmux was already running, restart it to pick up changes: `tmux kill-server`
- On macOS, you may need to set Ghostty's config path:
  ```bash
  defaults write com.mitchellh.ghostty ConfigPath -string "$HOME/.config/ghostty"
  ```
