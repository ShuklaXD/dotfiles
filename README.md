# Dotfiles

Personal dotfiles for zsh, vim, tmux, git, and more.

## Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## What's Included

| Config | Description |
|--------|-------------|
| **zsh** | Oh My Zsh + Powerlevel10k + autosuggestions + syntax highlighting |
| **vim** | vim-plug + 16 plugins (gruvbox, fzf, NERDTree, ALE, fugitive, etc.) |
| **tmux** | Prefix `Ctrl+a`, vim navigation, gruvbox status bar |
| **git** | Global gitconfig |
| **htop** | htop settings |

## What the Installer Does

1. Installs system packages (git, curl, vim, tmux, zsh, htop, etc.)
2. Installs Homebrew (Linux/macOS)
3. Installs brew packages (node, go, python)
4. Installs Oh My Zsh + plugins (autosuggestions, syntax-highlighting)
5. Installs Powerlevel10k theme
6. Installs NVM (Node Version Manager)
7. Installs fzf (fuzzy finder)
8. Symlinks all dotfiles (backs up existing ones)
9. Installs vim-plug + all vim plugins
10. Sets zsh as default shell

## Key Bindings

### Vim (Leader = Space)
- `Space ff` — fuzzy find files
- `Space fg` — ripgrep search
- `Space e` — toggle NERDTree
- `Space gs` — git status
- `Space u` — undo tree

### Tmux (Prefix = Ctrl+a)
- `Prefix |` — vertical split
- `Prefix -` — horizontal split
- `Prefix h/j/k/l` — navigate panes
- `Prefix r` — reload config
