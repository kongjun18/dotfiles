# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Exit for non-interactive shell
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
	zinit ice depth"1" lucid
	zinit light zsh-users/zsh-syntax-highlighting
	zinit ice depth"1"
	zinit light jeffreytse/zsh-vi-mode
	# zinit ice lucid wait"0a" from"gh-r" as"program" atload'eval "$(mcfly init zsh)"'
	# zinit light cantino/mcfly
	# git-extras
	zinit lucid wait'0a' for \
	as"program" pick"$ZPFX/bin/git-*" src"etc/git-extras-completion.zsh" make"PREFIX=$ZPFX" tj/git-extras

	# zsh-vi-mode default edit or
	ZVM_VI_EDITOR="nvim"
fi

#######################################
#       Software Configuration        #
#######################################

# Golang
export GOPATH=~/.go
export GOROOT=~/.goroot
export GO111MODULE=on
export GOPROXY=https://goproxy.cn
export EDITOR="nvim"

# Nodejs
export NPM_PREFIX=~/.npm # npm local prefix(not used by npm)

# Load xmake profile
Z_LUA_PATH="${HOME}/.local/z.lua"
if type lua &> /dev/null; then
	LUA=lua
elif type luajit &> /dev/null; then
	LUA=luajit
fi
[[ -s "${HOME}/.xmake/profile" ]] && source "$HOME/.xmake/profile"

# Download lua and z.lua
if [[ ! -d "${Z_LUA_PATH}" ]]; then
	git clone --depth 1 https://github.com/skywind3000/z.lua.git ~/.local/z.lua
fi
if [[ -z "${LUA}" ]]; then
	mkdir -p ~/.tmp/
	git clone --depth 1 --branch v2.0.5 https://github.com/LuaJIT/LuaJIT.git ~/.tmp/LuaJIT \
		&& (cd ~/.tmp/LuaJIT && make && make install PREFIX="${HOME}/.local" && chmod u+x ~/.local/bin/luajit)
	rm -rf ~/.tmp
	if type luajit &> /dev/null; then
		LUA=luajit
	fi
fi

# mcfly
export MCFLY_LIGHT=TRUE     # Light mode
export MCFLY_KEY_SCHEME=vim # Vim keybind
export MCFLY_FUZZY=2        # Fuzzy match

############################
#           Alias          #
############################
if [[ -d "${Z_LUA_PATH}" ]] || [[ -n "${LUA}" ]]; then
	eval "$(${LUA} ${Z_LUA_PATH}/z.lua --init zsh)"
	alias zb="z -b"
else
	alias z="echo -e '\e[1;31mz.lua is not available\e[0m' > /dev/stderr"
fi
unset Z_LUA_PATH

alias vi="nvim"
alias tm="tmux"
alias g="git"
alias grep="grep  --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}"
alias diff="diff --color -u"
if [ -x /usr/bin/dircolors ]; then
	test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
	alias ls="ls --color=auto"
fi
if [[ "${TERM_PROGRAM}" == "WezTerm" ]]; then
	alias icat="wezterm imgcat"
else
	alias icat="chafa"
fi

# K8S
alias kcd='kubectl config set-context $(kubectl config current-context) --namespace'

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

# Enable kubernetes completion
if type kubectl &> /dev/null; then
	source <(kubectl completion zsh)
fi

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
#    Post Init Hook   #
#######################
function zvm_after_init() {          # Execute aftar zsh-vi-mode
	if type mcfly &> /dev/null; then # Load mcfly scripts
		eval "$(mcfly init zsh)"
	fi
}
export PATH="${HOME}/.zsh/bin:${HOME}/.bin:${HOME}/.local/bin:${GOPATH}/bin::${GOROOT}/bin:${NPM_PREFIX}/bin:/sbin:${PATH}"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
