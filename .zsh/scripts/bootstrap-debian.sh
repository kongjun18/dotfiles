#!/bin/bash
#
# Configure development environment on empty Debian machine.
#
# Usage: Executed from upper script.
#
# Notes:
# - All operations are idempotent.
# - Tested on Debian 11.3.
#
# Author: Kong Jun <kongjun18@outlook.com>

#####################################################
# Bootstrap options
#####################################################

# Neovim-nightly PPA Ubuntu version
readonly Ubuntu="focal"
# Neovim-nightly PPA signing key.
# See https://launchpad.net/~neovim-ppa/+archive/ubuntu/unstable.
readonly NeovimPpaKey="9DBB0BE9366964F134855E2255F96FCF8231B6DD"
# Local kongjun18/dotfiles directory
readonly Dotfiles="${HOME}/.dotfiles"
readonly DotfilesBackup="${HOME}/.dotfiles-backup"
readonly GolangFile="go1.18.1.linux-amd64.tar.gz"

#####################################################
# Utilies
#####################################################

# Print error and exit
function EchoErr() {
  local red='\e[1;31m'
  local reset='\e[0m'
  echo -e "${red}${*}${reset}" > /dev/stderr
  exit 1
}

function EchoInfo() {
  local green='\e[1;32m'
  local reset='\e[0m'
  echo -e "${green}${*}${reset}"
}

# Exit if cmd not exists
function CheckCmd() {
  for exe in "$@"; do
    if ! type "${exe}" &> /dev/null; then
      EchoErr "Please install ${exe} or update your path to include the ${exe} executable!"
    fi
  done
}

function ConfigureEnv() {
  User="$(basename "$HOME")" # NOTE: Debian $USER is empty in docker build stage!
  IsDocker=0
  ResourceCleared=0
  if [[ -e /.dockerenv ]]; then
    IsDocker=1
  fi
}

function ClearResource() {
  set +e
  if [[ ${ResourceCleared} -eq 0 ]]; then
    rm "/tmp/${GolangFile}"
    rm -rf /var/lib/apt/lists/*
    apt-get update
  fi
  ResourceCleared=1
  set -e
}

function HandleErr() {
  if [[ "${#}" -eq 2 ]]; then
    EchoErr "Encounter error in line ${2}, exit code ${1}"
  else
    EchoErr "Encounter error"
  fi
  EchoErr "Clearing resource"
  ClearResource
}

function DebianCode() {
  CheckCmd 'awk'
  awk '{print $2}' /etc/os-release | grep -o '(.*)' | cut -d '(' -f 2 | cut -d ')' -f 1
}

function Dotfile() {
  git --git-dir="${Dotfiles}" --work-tree="$HOME" "$@"
}

function BackupDotfiles() {
  for dir in $1; do
    if [[ -e "${dir}" ]]; then
      local d
      d="$(dirname "$dir")"
      local backup_dir="${DotfilesBackup}/${d}"
      backup_dir="${backup_dir:1}"
      UserMkdir "${backup_dir}"
      echo "Copy $dir to ${backup_dir}/$(basename "$dir")"
    fi
  done
}

# git clone wrapper which inputs "yes" automatically
function GitClone() {
  CheckCmd 'expect'
  expect <<EOF
set timeout 60
spawn git clone $*
expect {
  "continue connecting (yes/no" { send "yes\r"; exp_continue }
  eof
}
EOF
}

# chown wrapper which changes all upper directories' owner/group to ${User}.
#
# It don't follow symbol link.
function UserChown() {
  CheckCmd 'realpath'
  for file in "$@"; do
    file="$(realpath --no-symlinks "${file}")"
    while [[ "${file}" != "${HOME}" ]] && [[ "${file}" != "/" ]]; do
      chown "${User}:" "${file}"
      file="$(dirname "${file}")"
    done
  done
}

# chown wrapper which changes all upper directories and sub-directories
# owner/group to ${User}.
#
# It don't follow symbol link.
function RecursiveUserChown() {
  chown -R "${User}:" "$@"
  UserChown "$@"
}

# mkdir wrapper which create directories whose owner/group is ${User} .
function UserMkdir() {
  mkdir -p "$@"
  UserChown "$@"
}

#####################################################
# Installer
#####################################################

# Clone and configurate dotfiles git repo
function InstallDotfiles() {
  apt-get update -y && apt-get install -y zsh fzy lua5.1
  if [ -d "$Dotfiles" ]; then
    EchoInfo "${Dotfiles} exists"
    EchoInfo "It is unnessary to clone dotfiles"
  else
    GitClone --bare git@github.com:kongjun18/dotfiles.git "${Dotfiles}" \
    && RecursiveUserChown "${Dotfiles}"
  fi

  Dotfile config status.showUntrackedFiles no
  Dotfile push --set-upstream origin main # Set dotfiles upstream repo

  # Checkout dotfiles and backup pre-existing dotfiles
  local commited_files
  commited_files="$(Dotfile ls-tree --full-tree -r --name-only HEAD | xargs)"
  local files=()
  for file in ${commited_files}; do
    files+=("${HOME}/${file}")
  done
  if Dotfile checkout; then
    EchoInfo "Checked out dotfiles.";
  else
    EchoInfo "Backing up pre-existing dot files.";
    BackupDotfiles "${files[@]}" && Dotfile checkout --force
  fi
  EchoInfo "${files[@]}"
  UserChown "${files[@]}"
  EchoInfo "Install kongjun18/dotfiles successfully!"
}

function ConfigureApt() {
  # Configure apt and install necessary utilities
  local debian
  debian="$(DebianCode)"
  echo -e "deb http://mirror.lzu.edu.cn/debian/ ${debian} main contrib non-free
# deb-src http://mirror.lzu.edu.cn/debian/ ${debian} main contrib non-free
deb http://mirror.lzu.edu.cn/debian/ ${debian}-updates main contrib non-free
# deb-src http://mirror.lzu.edu.cn/debian/ ${debian}-updates main contrib non-free
deb http://mirror.lzu.edu.cn/debian/ ${debian}-backports main contrib non-free
# deb-src http://mirror.lzu.edu.cn/debian/ ${debian}-backports main contrib non-free
deb http://mirror.lzu.edu.cn/debian-security ${debian}-security main contrib non-free
# deb-src http://mirror.lzu.edu.cn/debian-security ${debian}-security main contrib non-free" > /etc/apt/sources.list \
  && apt-get update \
  && apt-get install -y ca-certificates apt-transport-https \
    sudo \
    git \
    gpg \
    curl wget \
    sed grep gawk \
    lsb-release \
    expect \
  && sed -i 's/http/https/g' /etc/apt/sources.list \
  && apt-get update
  EchoInfo "Configure apt successfully!"
}

function ConfigureSsh() {
  if [ ! -e "${HOME}/.ssh/id_ed25519" ]; then
    EchoErr "There is no ssh key id_ed25519"
  fi
  apt-get install -y openssh-client openssh-server \
    && eval "$(ssh-agent -s)" \
    && ssh-add ~/.ssh/id_ed25519
  if [[ ! -d ~/.ssh ]] || ! grep -q 'github' ~/.ssh/known_hosts; then
    UserMkdir ~/.ssh
    ssh-keyscan github.com >> ~/.ssh/known_hosts
  fi

  EchoInfo "Configure ssh successfully!"
}

# Change default shell to zsh and install zsh plugins
function ChangeDefaultShell() {
  usermod -s "$(which zsh)" "${User}" # Run this script in sudo to change shell directly
  zsh -c "export init=1 && source ~/.zshrc && exit" # Install zsh plugins
  EchoInfo "Change default shell to $(which zsh)!"
}

# Install GNU/Linux system utilities
function InstallUtilies() {
  apt-get install -y tmux net-tools netcat vmtouch sysstat autossh
  EchoInfo "Install system utilies successfully!"
}

function InstallDocker() {
  # Don't install docker in docker!
  if [[ ${IsDocker} -eq 1 ]]; then
    EchoInfo "Detected running in docker. Skip docker installation."
    return 0
  fi
  local docker_repo="https://mirrors.aliyun.com" # Install docker via Alibaba mirror
  CheckCmd 'curl' 'sh'
  if ! type 'docker' &> /dev/null; then
    curl -fsSL "${docker_repo}"/docker-ce/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] ${docker_repo}/docker-ce/linux/debian $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update  && apt-get install -y docker-ce docker-ce-cli containerd.io
    # Add user to docker group
    # Ignore error
    set +e
    /sbin/groupadd 'docker'
    /sbin/usermod -G 'docker' "${User}"
    set -e
  fi
  EchoInfo "Install docker successfully!"
}

function InstallGolang() {
  # Install Golang
  if ! type 'go' &> /dev/null && [[ ! -e '/usr/local/go/bin/go' ]]; then
    apt-get install -y axel tar \
      && axel -n"$(nproc)" "https://studygolang.com/dl/golang/${GolangFile}" -o "/tmp/${GolangFile}" \
      && tar -xzv -f "/tmp/${GolangFile}" -C /usr/local/ > /dev/null
  fi
  EchoInfo "Install Golang successfully!"
}

# Install neovim-nightly via neovim-nightly ppa
#
# NOTE: I am not sure it works in the furture.
function InstallNeovim() {
  if ! type 'nvim' &> /dev/null; then
    apt-get update && apt-get install -y gnupg gpg software-properties-common \
      && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys  "${NeovimPpaKey}"\
      && echo -e "deb [arch=amd64] https://ppa.launchpadcontent.net/neovim-ppa/unstable/ubuntu ${Ubuntu} main
deb-src [arch=amd64] https://ppa.launchpadcontent.net/neovim-ppa/unstable/ubuntu ${Ubuntu} main" > /etc/apt/sources.list.d/neovim-ppa.list \
      && apt-get update && apt-get -y install neovim
  fi
  EchoInfo "Install neovim-nightly successfully!"
}

# Install kongjun18/nvim
function InstallNvimConfig() {
  if [[ ! -d "${HOME}/.config/nvim" ]]; then
    GitClone git@github.com:kongjun18/nvim.git ~/.config/nvim \
      && RecursiveUserChown ~/.config/nvim
      # && ~/.config/nvim/scripts/debian-install.sh
    [[ -d ~/.local/nvim ]] && RecursiveUserChown ~/.local/nvim
    [[ -d ~/.cache ]] && RecursiveUserChown ~/.cache
  fi
  EchoInfo "Install kongjun18/nvim successfully!"
}

#####################################################
# Main logic
#####################################################
function main() {
  # Exit when encounter error
  set -e
  set -o pipefail

  ConfigureEnv
  ConfigureApt
  ConfigureSsh

  InstallUtilies
  InstallGolang
  InstallDocker
  InstallNeovim
  InstallNvimConfig
  InstallDotfiles
  ChangeDefaultShell
}

trap 'HandleErr "$?" "$LINENO"' ERR
trap 'ClearResource' EXIT

main
