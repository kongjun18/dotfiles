# shellcheck disable=SC2034,SC2190,SC1094,SC2016,SC1091
# shellcheck disable=SC2086,SC2296,SC1090,SC2153

# Exit for non-interactive shell
[[ $- != *i* ]] && return

############################
#         Utilities        #
############################
function exists() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

unameOut="$(uname -s)"
export MACHINE
export ARCH
case "${unameOut}" in
    Linux*)
        MACHINE=Linux
        export LINUX_RELEASE
        LINUX_RELEASE="$(grep '^ID=' /etc/os-release | cut -d = -f 2)"
        ;;
    Darwin*)    MACHINE=Mac;;
    CYGWIN*)    MACHINE=Windows;;
    MINGW*)     MACHINE=Windows;;
    MSYS_NT*)   MACHINE=Windows;;
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
		BIN_DIR  "$HOME/.zsh/zinit/bin"
		HOME_DIR "$HOME/.zsh/zinit"
		COMPINIT_OPTS -C
	)
	source "$HOME/.zsh/zinit/zinit.zsh"

	# Load zsh plugins
	zinit ice depth"1"
	zinit light romkatv/zsh-defer

	zsh-defer zinit ice depth"1" wait lucid atload'_zsh_autosuggest_start'
	zsh-defer zinit light zsh-users/zsh-autosuggestions

	zinit ice depth"1"
	zinit light romkatv/powerlevel10k

	zsh-defer zinit ice depth"1" wait lucid src'zsh-syntax-highlighting.zsh'
	zsh-defer zinit light zsh-users/zsh-syntax-highlighting

    # DO NOT LAZY LOAD zsh-vi-mode for the following reasons:
    # 1. Override all keybindings and solutions in
    #    https://github.com/jeffreytse/zsh-vi-mode?tab=readme-ov-file#execute-extra-commands
    #    do not work.
    # 2. Lazy loading only speeds up the creation of new sessions; in reality,
    #    you still have to wait until zsh-vi-mode is loaded before you can use it.
	zinit ice depth"1"
	zinit light jeffreytse/zsh-vi-mode
fi

###################################
#       Download Softwares        #
###################################
if ! exists gcc; then
    if [[ "${MACHINE}" == "Linux" ]]; then
        bash ~/.zsh/scripts/build-essential.sh
    fi
fi
[[ "${MACHINE}" == "Linux" ]] && pick_musl_on_linux='bpick*linux-musl*' && pick_targz_on_linux="bpick*tar.gz"
[[ "${MACHINE}" == "Windows" ]] && pick_windows='bpick*windows*' && pick_zip_on_windows="bpick*win*.zip"
zinit light-mode for zdharma-continuum/zinit-annex-bin-gem-node
zsh-defer zinit as"program" from"gh-r" wait light-mode lucid for \
        atload'eval "$(mcfly init zsh)"' \
        sbin"**/mcfly" \
    ${pick_windows} cantino/mcfly \
    sbin"**/delta" ${pick_windows} ${pick_musl_on_linux} @dandavison/delta \
    sbin"**/rg" ${pick_windows} @BurntSushi/ripgrep \
    sbin"**/fd" @sharkdp/fd \
    ver"v12.1.2" ${pick_windows} @XAMPPRocky/tokei \
    ver"v0.61.2" sbin"fzf" ${pick_windows} @junegunn/fzf \
    sbin"grpcurl" ${pick_windows} @fullstorydev/grpcurl \
    ${pick_windows} nocompile @jqlang/jq \
    nocompletions \
    pick"*/bin/nvim" \
    ${pick_zip_on_windows} ${pick_targz_on_linux} neovim/neovim
zsh-defer zinit as"null" wait light-mode depth"1" lucid for \
        src"etc/git-extras-completion.zsh" \
        make"PREFIX=${ZPFX}" \
    tj/git-extras \
    	cloneopts"--branch v5.3" \
        atclone"make -j && cp --force lua ${ZPFX}/bin/lua" \
        atpull"%atclone" \
    lua/lua \
        atload'eval "$(lua z.lua --init zsh)"' \
    skywind3000/z.lua \
        atclone"./autogen.sh && ./configure && make && cp --force ctags ${ZPFX}/bin/ctags" \
        atpull"%atclone" \
    universal-ctags/ctags

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
ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
ZVM_VI_EDITOR="nvim --cmd 'let g:bare_mode=v:true' -c 'set wrap'"

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

# nodejs
export NPM_PREFIX=~/.npm # npm local prefix(not used by npm)

# mcfly
export MCFLY_KEY_SCHEME=vim # Vim keybind
export MCFLY_FUZZY=2        # Fuzzy match

# fzf
export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'

############################
#           Alias          #
############################
alias zb="z -b"
alias yadm="yadm --yadm-repo ~/.local/share/yadm/repo.git"
alias vi="nvim"
alias vim="nvim --cmd 'let g:bare_mode=v:true'"
alias em="emacs -nw"
alias tm="tmux"
alias g="git"
alias grep="grep  --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}"
alias py="python3"
alias gdb="gdb -q"
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
autoload -U colors
colors

autoload -U compinit
compinit

# zsh-vi-mode #159: zvm_cursor_style errors out every return
setopt re_match_pcre

# Completion path
export fpath=($fpath "${HOME}/.zsh/completion")

# Case-insensitive
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'

# Enable file color eval $(dircolors -b)
export ZLSCOLORS="${LS_COLORS}"
zmodload zsh/complist
zstyle ':completion:*' menu select
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
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.
setopt HIST_FCNTL_LOCK           # Achieve better performance and avoid history corruption on NFS.
setopt HIST_NO_STORE             # Don't store history (fc -l) command.
setopt HIST_NO_FUNCTIONS         # Don't store function definitions.

# Only save successful commands into zsh history file, seeing
# https://scarff.id.au/blog/2019/zsh-history-conditional-on-command-success/.

# Prevent the command from being written to history before it's
# executed; save it to LASTHIST instead.  Write it to history
# in precmd.
#
# zsh hook called before a history line is saved.  See zshmisc(1).
function zshaddhistory() {
  # Remove line continuations since otherwise a "\" will eventually
  # get written to history with no newline.
  LASTHIST=${1//\\$'\n'/}
  # Return value 2: "... the history line will be saved on the internal
  # history list, but not written to the history file".
  return 2
}

# zsh hook called before the prompt is printed.  See zshmisc(1).
function precmd() {
  # Write the last command if successful, using the history buffered by
  # zshaddhistory().
  if [[ $? == 0 && -n ${LASTHIST//[[:space:]\n]/} && -n $HISTFILE ]] ; then
    print -sr -- ${=${LASTHIST%%'\n'}}
  fi
}


#######################
#      Bindings       #
#######################
# Keybindings MUST be put in zvm_after_init which executes after zsh-vi-mode is loaded.
# Otherwise, keybindings will be overridden by zsh-vi-mode.
function zvm_after_init() {
    bindkey '^j' forward-word
    bindkey '^k' backward-delete-word
    bindkey '^[[Z' reverse-menu-complete
}

#######################
#    Post Init Hook   #
#######################
function source_profiles() {
    [[ -f ~/.zsh/scripts/setup.sh ]] && source ~/.zsh/scripts/setup.sh
    [[ -s "${HOME}/.xmake/profile" ]] && source "$HOME/.xmake/profile"
    [[ -f "$HOME/.cargo/env" ]] && source $HOME/.cargo/env
}
zsh-defer source_profiles

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export PATH="${HOME}/.zsh/bin:${HOME}/.bin:${HOME}/.local/bin:${GOPATH}/bin:${GOROOT}/bin:${NPM_PREFIX}/bin:/sbin:${PATH}"
