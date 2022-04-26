# # Exit for non-interactive shell
if [[ ${init} -ne 1 ]]; then
	[[ $- != *i* ]] && return
fi

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
	zinit ice depth"1" wait"0" lucid
	zinit light zsh-users/zsh-syntax-highlighting
	zinit ice depth"1"
	zinit light jeffreytse/zsh-vi-mode

	# zsh-theme-powerlevel9k uses nerdfont
	POWERLEVEL9K_MODE="nerdfont-complete"
	POWERLEVEL9K_PROMPT_ON_NEWLINE=true
	# zsh-theme-powerlevel9k uses nerdfont
	POWERLEVEL9K_MODE="nerdfont-complete"
	# zsh-theme-powerlevel9k adds new line before each prompt
	POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
	# zsh-theme-powerlevel9k prompt prefix: $
	POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
	POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="$ "
	# zsh-theme-powerlevel9k light colorscheme
	POWERLEVEL9K_COLOR_SCHEME='light'
	# zsh-theme-powerlevel9k prompt
	POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status time)
	POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(vi_mode host dir)
	# zsh-theme-powerlevel9k vi mode color
	POWERLEVEL9K_VI_MODE_INSERT_FOREGROUND=black
	POWERLEVEL9K_VI_MODE_NORMAL_FOREGROUND=black
	POWERLEVEL9K_VI_MODE_VISUAL_FOREGROUND=black
	POWERLEVEL9K_VI_MODE_INSERT_BACKGROUND=green
	POWERLEVEL9K_VI_MODE_NORMAL_BACKGROUND=blue
	POWERLEVEL9K_VI_MODE_VISUAL_BACKGROUND=yellow

	# zsh-vi-mode default edit or
	ZVM_VI_EDITOR="nvim"
fi

############################
#       Environment        #
############################
export GOPATH=~/go
export GO111MODULE=on
export GOPROXY=https://goproxy.cn
export EDITOR="nvim"
export PATH="${HOME}/.zsh/bin:${HOME}/.local/bin:${HOME}/go/bin:${HOME}/.cargo/bin:/usr/local/go/bin:${PATH}"
# Load xmake profile
Z_LUA_PATH="${HOME}/.local/z.lua"
[[ -s "${HOME}/.xmake/profile" ]] && source "$HOME/.xmake/profile"
# Load z.lua profile
if [[ ! -d "${Z_LUA_PATH}" ]]; then
	git clone --depth 1 https://github.com/skywind3000/z.lua.git ~/.local/z.lua
fi
if [[ -d "${Z_LUA_PATH}" ]] && type 'lua' &> /dev/null; then
	eval "$(lua /usr/local/src/z.lua/z.lua --init zsh)"
else
	alias z="echo -e '\e[1;31mz.lua is not available\e[0m' > /dev/stderr"
fi
unset Z_LUA_PATH

############################
#           Alias          #
############################
alias vi="nvim"
alias tm="tmux"
alias g="git"
alias grep="grep  --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}"
alias dotfiles="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
if [ -x /usr/bin/dircolors ]; then
	test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
	alias ls="ls --color=auto"
fi
[[ "${TERM}" == "xterm-kitty" ]] && alias ssh="kitty +kitten ssh"

############################
#       Configuration      #
############################
autoload -U colors && colors
autoload -U compinit
compinit

# Enable file color
eval $(dircolors -b)
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

############################
#        Functions         #
############################
function git-rm-untracked() {
	git status -s | grep '^??' | awk '{print $2}' | xargs rm -r
}

function cpptest() {
	local name="${1:-cpptest}"
	local dir="/tmp/${name}"
	if [ -d "${dir}" ]; then
		nvim "${dir}/${name}.cc"
	else
		mkdir "${dir}" && touch "${dir}/.ccls" && touch "${dir}/${name}.cc" && nvim "${dir}/${name}.cc"
	fi
}
