#!/usr/bin/env bash

set -e

echo "==> Detecting OS..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Error: Cannot detect OS"
    exit 1
fi

echo "==> Detected OS: $OS"

# Install packages based on OS
case $OS in
    ubuntu|debian)
        echo "==> Installing packages on Debian/Ubuntu..."
        sudo apt update
        sudo apt install -y yadm lua5.1 zsh git universal-ctags
        ;;
    arch|manjaro)
        echo "==> Installing packages on Arch Linux..."
        sudo pacman -Sy --noconfirm yadm lua zsh git ctags
        ;;
    *)
        echo "Error: Unsupported OS: $OS"
        echo "Supported: ubuntu, debian, arch, manjaro"
        exit 1
        ;;
esac

echo "==> Cloning dotfiles..."
if [ -d "$HOME/.local/share/yadm/repo.git" ]; then
    echo "Dotfiles already cloned, skipping..."
else
    yadm clone https://github.com/kongjun18/dotfiles
    echo "Dotfiles cloned successfully"
fi

echo "==> Changing shell to zsh..."
if [ "$SHELL" = "$(which zsh)" ]; then
    echo "Shell is already zsh, skipping..."
else
    chsh -s "$(which zsh)"
    echo "Shell changed to zsh. Please log out and log back in for changes to take effect."
fi

echo ""
echo "==> Bootstrap complete!"
echo "==> Next steps:"
echo "    1. Log out and log back in (or restart your terminal)"
echo "    2. Start zsh - it will install zinit and powerlevel10k automatically"
echo "    3. Your p10k configuration will be applied from ~/.p10k.zsh"
