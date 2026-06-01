#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ---------------------------------------------------------------------------
# Backup existing dotfile before symlinking
# ---------------------------------------------------------------------------
backup_and_link() {
    local src="$1"
    local dest="$2"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        mkdir -p "$BACKUP_DIR"
        cp -rL "$dest" "$BACKUP_DIR/" 2>/dev/null || true
        rm -rf "$dest"
        warn "Backed up existing $(basename "$dest") to $BACKUP_DIR/"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    success "Linked $(basename "$dest")"
}

# ---------------------------------------------------------------------------
# Detect OS
# ---------------------------------------------------------------------------
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ "$(uname)" = "Darwin" ]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
info "Detected OS: $OS"

# ---------------------------------------------------------------------------
# Install system packages
# ---------------------------------------------------------------------------
install_packages() {
    info "Installing system packages..."

    local packages=(git curl wget vim tmux zsh htop build-essential xclip unzip)

    case "$OS" in
        ubuntu|debian|pop)
            sudo apt update -qq
            sudo apt install -y "${packages[@]}"
            ;;
        fedora)
            sudo dnf install -y "${packages[@]/%build-essential/gcc gcc-c++ make}"
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm "${packages[@]/%build-essential/base-devel}"
            ;;
        macos)
            if ! command -v brew &>/dev/null; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install git curl wget vim tmux zsh htop
            ;;
        *)
            warn "Unknown OS — skipping system package install. Install manually: ${packages[*]}"
            ;;
    esac
    success "System packages installed"
}

# ---------------------------------------------------------------------------
# Install Homebrew (Linux)
# ---------------------------------------------------------------------------
install_homebrew() {
    if command -v brew &>/dev/null; then
        success "Homebrew already installed"
        return
    fi

    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to current session
    if [ -d /home/linuxbrew/.linuxbrew ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [ -d "$HOME/.linuxbrew" ]; then
        eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
    fi
    success "Homebrew installed"
}

# ---------------------------------------------------------------------------
# Install brew packages
# ---------------------------------------------------------------------------
install_brew_packages() {
    if ! command -v brew &>/dev/null; then
        warn "Homebrew not found — skipping brew packages"
        return
    fi

    info "Installing brew packages..."
    local brew_packages=(node go python@3 git-lfs)

    for pkg in "${brew_packages[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            success "$pkg already installed"
        else
            brew install "$pkg"
            success "$pkg installed"
        fi
    done
}

# ---------------------------------------------------------------------------
# Install Oh My Zsh
# ---------------------------------------------------------------------------
install_ohmyzsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        success "Oh My Zsh already installed"
    else
        info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        success "Oh My Zsh installed"
    fi
}

# ---------------------------------------------------------------------------
# Install Zsh plugins
# ---------------------------------------------------------------------------
install_zsh_plugins() {
    local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    info "Installing zsh plugins..."

    if [ ! -d "$custom/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions"
        success "zsh-autosuggestions installed"
    else
        success "zsh-autosuggestions already installed"
    fi

    if [ ! -d "$custom/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$custom/plugins/zsh-syntax-highlighting"
        success "zsh-syntax-highlighting installed"
    else
        success "zsh-syntax-highlighting already installed"
    fi
}

# ---------------------------------------------------------------------------
# Install Powerlevel10k
# ---------------------------------------------------------------------------
install_p10k() {
    local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [ -d "$custom/themes/powerlevel10k" ]; then
        success "Powerlevel10k already installed"
    else
        info "Installing Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$custom/themes/powerlevel10k"
        success "Powerlevel10k installed"
    fi
}

# ---------------------------------------------------------------------------
# Install NVM
# ---------------------------------------------------------------------------
install_nvm() {
    if [ -d "$HOME/.nvm" ]; then
        success "NVM already installed"
    else
        info "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        success "NVM installed"
    fi
}

# ---------------------------------------------------------------------------
# Install fzf
# ---------------------------------------------------------------------------
install_fzf() {
    if command -v fzf &>/dev/null; then
        success "fzf already installed"
        return
    fi

    info "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --all --no-bash --no-fish
    success "fzf installed"
}

# ---------------------------------------------------------------------------
# Symlink dotfiles
# ---------------------------------------------------------------------------
link_dotfiles() {
    info "Symlinking dotfiles..."

    backup_and_link "$DOTFILES_DIR/zsh/.zshrc"       "$HOME/.zshrc"
    backup_and_link "$DOTFILES_DIR/zsh/.p10k.zsh"    "$HOME/.p10k.zsh"
    backup_and_link "$DOTFILES_DIR/vim/.vimrc"        "$HOME/.vimrc"
    backup_and_link "$DOTFILES_DIR/tmux/.tmux.conf"   "$HOME/.tmux.conf"
    backup_and_link "$DOTFILES_DIR/git/.gitconfig"    "$HOME/.gitconfig"

    if [ -f "$DOTFILES_DIR/config/htop/htoprc" ]; then
        backup_and_link "$DOTFILES_DIR/config/htop/htoprc" "$HOME/.config/htop/htoprc"
    fi

    success "All dotfiles linked"
}

# ---------------------------------------------------------------------------
# Install vim-plug and plugins
# ---------------------------------------------------------------------------
install_vim_plugins() {
    info "Installing vim-plug..."
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    success "vim-plug installed"

    info "Installing vim plugins..."
    mkdir -p "$HOME/.vim/undodir"
    vim -es -u "$HOME/.vimrc" +PlugInstall +qall 2>/dev/null || true
    success "Vim plugins installed"
}

# ---------------------------------------------------------------------------
# Set default shell to zsh
# ---------------------------------------------------------------------------
set_default_shell() {
    if [ "$SHELL" = "$(which zsh)" ]; then
        success "Default shell is already zsh"
        return
    fi

    local zsh_path
    zsh_path="$(which zsh)"

    if ! grep -q "$zsh_path" /etc/shells; then
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    info "Changing default shell to zsh..."
    chsh -s "$zsh_path" || warn "Could not change shell — run manually: chsh -s $zsh_path"
    success "Default shell set to zsh"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Dotfiles Installer                    ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""

    install_packages
    install_homebrew
    install_brew_packages
    install_ohmyzsh
    install_zsh_plugins
    install_p10k
    install_nvm
    install_fzf
    link_dotfiles
    install_vim_plugins
    set_default_shell

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  All done!                             ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "  ${YELLOW}Next steps:${NC}"
    echo -e "  1. Restart your terminal or run: ${BLUE}exec zsh${NC}"
    echo -e "  2. If p10k prompt looks off, install a Nerd Font:"
    echo -e "     ${BLUE}https://www.nerdfonts.com/font-downloads${NC}"
    echo -e "  3. Run ${BLUE}p10k configure${NC} to reconfigure the prompt"
    echo -e "  4. Update git config: ${BLUE}git config --global user.name \"Your Name\"${NC}"
    echo -e "     ${BLUE}git config --global user.email \"you@example.com\"${NC}"
    echo ""
}

main "$@"
