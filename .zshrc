# Exit for non-interactive shell
if [[ ${init} -ne 1 ]]; then
	[[ $- != *i* ]] && return
fi

############################
#         Utilities        #
############################
function exists() {
    if command -v $1 &> /dev/null; then
        return 0
    else
        return 1
    fi
}

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    CYGWIN*)    MACHINE=Cygwin;;
    MINGW*)     MACHINE=MinGw;;
    MSYS_NT*)   MACHINE=Git;;
    *)          MACHINE="UNKNOWN:${unameOut}"
esac


############################
#     Load zsh plugins     #
############################
if [[ ! -d "$HOME/.zsh/zinit" ]]; then
	git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$HOME/.zsh/zinit"
fi
if [[ -e "${HOME}/.zsh/zinit/zinit.zsh" ]]; then
	typeset -A ZINIT=(
		BIN_DIR  $HOME/.zsh/zinit/bin
		HOME_DIR $HOME/.zsh/zinit
		COMPINIT_OPTS -C
	)
	source $HOME/.zsh/zinit/zinit.zsh

	# Load zsh plugins
	zinit ice depth"1" wait lucid atload'_zsh_autosuggest_start'
	zinit light zsh-users/zsh-autosuggestions
	zinit ice depth"1"
	zinit light romkatv/powerlevel10k
	zinit ice depth"1" wait lucid src'zsh-syntax-highlighting.zsh'
	zinit light zsh-users/zsh-syntax-highlighting
	zinit ice depth"1"
	zinit light jeffreytse/zsh-vi-mode
fi

###################################
#       Download Softwares        #
###################################
[[ "${MACHINE}" == "Linux" ]] && pick_musl_on_linux='bpick*musl*'
zinit light-mode for zdharma-continuum/zinit-annex-bin-gem-node
zinit as"null" from"gh-r" wait light-mode lucid for \
        atload'eval "$(mcfly init zsh)"' \
        sbin"**/mcfly" \
    cantino/mcfly \
    sbin"**/delta" ${pick_musl_on_linux} @dandavison/delta \
    sbin"**/rg" @BurntSushi/ripgrep \
    sbin"**/fd" @sharkdp/fd \
    ver"v12.1.2" sbin"**/tokei" @XAMPPRocky/tokei \
    sbin"fzf" @junegunn/fzf \
    sbin"grpcurl" @fullstorydev/grpcurl \
    sbin'* -> jq' nocompile @jqlang/jq
zinit as"null" wait light-mode depth"1" lucid for \
        src"etc/git-extras-completion.zsh" \
        make"PREFIX=${ZPFX}" \
    tj/git-extras \
        cloneopts"--branch v5.3" \
        atclone"make && cp --force lua ${ZPFX}/bin/lua" \
        atpull"%atclone" \
    lua/lua \
        atload'eval "$(lua z.lua --init zsh)"' \
    skywind3000/z.lua
zinit as"program" from"gh-r" wait lucid light-mode for \
        nocompletions \
        ver"nightly" \
        pick"*/bin/nvim" \
    neovim/neovim

# ###########################################
#       Powerlevel10k instant prompt        #
#############################################
# Should stay close to the top of ~/.zshrc. Initialization code that may
# require console input (password prompts, [y/n] confirmations, etc.) must
# go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

####################################
#      Plugin Configuration        #
####################################
ZVM_VI_EDITOR="nvim --cmd 'let g:bare_mode=v:true' -c 'set wrap'" # zsh-vi-mode default editor

#######################################
#       Software Configuration        #
#######################################
# Golang
export GOPATH=~/.go
export GOROOT=~/.go/go
export GO111MODULE=on

# Man pages
export EDITOR="nvim"
export MANPAGER='nvim +Man!'
export MANWIDTH=999

# Nodejs
export NPM_PREFIX=~/.npm # npm local prefix(not used by npm)

# Load xmake profile
[[ -s "${HOME}/.xmake/profile" ]] && source "$HOME/.xmake/profile"

# mcfly
export MCFLY_KEY_SCHEME=vim # Vim keybind
export MCFLY_FUZZY=2        # Fuzzy match

# fzf
# Speedup search
export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'

############################
#           Alias          #
############################
alias zb="z -b"
alias yadm="yadm --yadm-repo ~/.local/share/yadm/repo.git"
alias vi="nvim"
alias vim="nvim --cmd 'let g:bare_mode=v:true'"
alias ex="emacs -nw"
alias tm="tmux"
alias g="git"
alias grep="grep  --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}"
alias py="python3"
# diff on Darwin doesn't support --color
if [[ "${MACHINE}" == "Linux" ]]; then
    alias diff="diff --color -u"
elif [[ "${MACHINE}" == "Mac" ]]; then
    if exists git; then
        alias diff="git diff --no-index --color -u"
    fi
fi
if exists dircolors; then
  eval "$(dircolors -b)"
  zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
  alias ls='ls --color'
else
  export CLICOLOR=1
  zstyle ':completion:*:default' list-colors ''
fi
if [[ "${TERM_PROGRAM}" == "WezTerm" ]]; then
	alias icat="wezterm imgcat"
else
	alias icat="chafa"
fi

################################
#       ZSH Configuration      #
################################
autoload -U colors && colors
autoload -U compinit
compinit

# Completion path
export fpath=($fpath "${HOME}/.zsh/completion")

# Case-insensitive
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'

# Enable file color eval $(dircolors -b)
export ZLSCOLORS="${LS_COLORS}"
zmodload zsh/complist
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

# Configurate zsh history
HISTFILE="$HOME/.zsh/zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.


#######################
#      Bindings       #
#######################
function bind_keys() {
    bindkey '^j' forward-word
    bindkey '^k' backward-delete-word
    bindkey '^[[Z' reverse-menu-complete
}

#######################
#    Post Init Hook   #
#######################
# Execute aftar zsh-vi-mode
function zvm_after_init() {
    bind_keys
}

export PATH="${HOME}/.zsh/bin:${HOME}/.bin:${HOME}/.local/bin:${GOPATH}/bin:${GOROOT}/bin:${NPM_PREFIX}/bin:/sbin:${PATH}"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
