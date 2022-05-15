#!/bin/bash
#
# Configure development environment on empty Debian machine.
#
# Usages:
# - Executed from upper script.
# - sudo --preserve-env={HOME,USER} bash bootstrap-debian.sh
#
# Notes:
# - All operations are idempotent.
# - Tested on Debian 11.3.
#
# Author: Kong Jun <kongjun18@outlook.com>

#####################################################
# Bootstrap options
#####################################################

# Time zone
readonly TimeZone="Asia/Shanghai"
# Linux open source software mirror
readonly OpenSourceMirror="mirror.lzu.edu.cn"
# Neovim-nightly PPA Ubuntu version
NeovimPPAUbuntuCode="bionic"
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
function Fatal() {
  local red='\e[1;31m'
  local reset='\e[0m'
  echo -e "${red}${*}${reset}" > /dev/stderr
  exit 1
}

function Info() {
  local green='\e[1;32m'
  local reset='\e[0m'
  echo -e "${green}${*}${reset}"
}

# Exit if cmd not exists
function CheckCmd() {
  for exe in "$@"; do
    if ! type "${exe}" &> /dev/null; then
      Fatal "Please install ${exe} or update your path to include the ${exe} executable!"
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

function GracefulExit() {
  Info "Exiting..."
  set +e
  if [[ ${ResourceCleared} -eq 0 ]]; then
    if [[ -d "/tmp/${GolangFile}" ]]; then
      rm "/tmp/${GolangFile}"
    fi
    rm -rf /var/lib/apt/lists/*
    apt-get update
  fi
  ResourceCleared=1
  set -e
  Info "Exited Gracefully"
}

function HandleErr() {
  if [[ "${#}" -eq 2 ]]; then
    echo "\e[1;31mEncounter error in line ${2}, exit code ${1}\e[0m" > /dev/stderr
  else
    echo "\e[0mEncounter error\e[0m" > /dev/stderr
  fi
  Fatal ""  # Trigger GracefulExit()
}

# Get Linux distribution name.
# Distribution nane in /etc/os-release: ID=xxxxxx
function DistrName() {
  awk -F '=' '$1 ~ /^ID$/ {print $2}' /etc/os-release
}

function DebianCode() {
  awk '{print $2}' /etc/os-release | grep -o '(.*)' | cut -d '(' -f 2 | cut -d ')' -f 1
}

function UbuntuCode() {
  awk -F'=' '$1~/UBUNTU_CODENAME/ {print $2}' /etc/os-release
}

# Generate Debian/Ubuntu /etc/apt/source.list
function GenerateSourceList() {
  local codename
  case "$(DistrName)" in
    ubuntu|Ubuntu)
      codename="$(UbuntuCode)"
      echo -e "deb http://${OpenSourceMirror}/ubuntu/ ${codename} main restricted universe multiverse
      deb-src http://${OpenSourceMirror}/ubuntu/ ${codename} main restricted universe multiverse
      deb http://${OpenSourceMirror}/ubuntu/ ${codename}-security main restricted universe multiverse
      deb-src http://${OpenSourceMirror}/ubuntu/ ${codename}-security main restricted universe multiverse
      deb http://${OpenSourceMirror}/ubuntu/ ${codename}-updates main restricted universe multiverse
      deb-src http://${OpenSourceMirror}/ubuntu/ ${codename}-updates main restricted universe multiverse
      deb http://${OpenSourceMirror}/ubuntu/ ${codename}-backports main restricted universe multiverse
      deb-src http://${OpenSourceMirror}/ubuntu/ ${codename}-backports main restricted universe multiverse" > /etc/apt/sources.list
      ;;
    debian|Debian)
      codename="$(DebianCode)"
      echo -e "deb http://${OpenSourceMirror}/debian/ ${codename} main contrib non-free
      # deb-src http://${OpenSourceMirror}/debian/ ${codename} main contrib non-free
      deb http://${OpenSourceMirror}/debian/ ${codename}-updates main contrib non-free
      # deb-src http://${OpenSourceMirror}/debian/ ${codename}-updates main contrib non-free
      deb http://${OpenSourceMirror}/debian/ ${codename}-backports main contrib non-free
      # deb-src http://${OpenSourceMirror}/debian/ ${codename}-backports main contrib non-free
      deb http://${OpenSourceMirror}/debian-security ${codename}-security main contrib non-free
      # deb-src http://${OpenSourceMirror}/debian-security ${codename}-security main contrib non-free" > /etc/apt/sources.list
      ;;
    *)
      Fatal "Unsupported Platform"
      ;;
  esac
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
    Info "${Dotfiles} exists"
    Info "It is unnessary to clone dotfiles"
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
    Info "Checked out dotfiles.";
  else
    Info "Backing up pre-existing dot files.";
    BackupDotfiles "${files[@]}" && Dotfile checkout --force
  fi
  Info "dotfiles: ${files[*]}"
  UserChown "${files[@]}"

  Info "Install kongjun18/dotfiles successfully!"
}

function InstallNvimConfig() {
  # Install kongjun18/nvim
  # NOTE: You should install neovim plugins dependencies manualy.
  if [[ ! -d "${HOME}/.config/nvim" ]]; then
    GitClone git@github.com:kongjun18/nvim.git ~/.config/nvim \
      && RecursiveUserChown ~/.config/nvim
    if [[ -d ~/.local/nvim ]];then
      RecursiveUserChown ~/.local/nvim
    fi
    if [[ -d ~/.cache ]];then
      RecursiveUserChown ~/.cache
    fi
  fi
}

# Configure time zone to avoid inputting timezone manually when configure tzdata.
function ConfigureTimeZone() {
  if [[ ! -e /etc/localtime ]]; then
    ln -snf /usr/share/zoneinfo/"$TimeZone" /etc/localtime \
    && echo "$TimeZone" > /etc/timezone
  fi
}

# Configure apt and install necessary utilities
function ConfigureApt() {
  GenerateSourceList
  apt-get update \
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
    Info "Configure apt successfully!"
}

function ConfigureSsh() {
  if [ ! -e "${HOME}/.ssh/id_ed25519" ]; then
    Fatal "There is no ssh key id_ed25519"
  fi
  apt-get install -y openssh-client openssh-server \
    && eval "$(ssh-agent -s)" \
    && ssh-add ~/.ssh/id_ed25519
  if [[ ! -d ~/.ssh/known_hosts ]]; then
    UserMkdir ~/.ssh
    touch ~/.ssh/known_hosts && chown "${USER}": ~/.ssh/known_hosts
  fi
  if ! grep -q 'github' ~/.ssh/known_hosts; then
    ssh-keyscan github.com >> ~/.ssh/known_hosts
  fi
  Info "Configure ssh successfully!"
}

# Change default shell to zsh and install zsh plugins
# NOTE: Run after InstallDotfiles()
function InstallZsh() {
  apt-get -y install zsh
  usermod -s "$(which zsh)" "${User}" # Run this script in sudo to change shell directly
  sudo -u "${User}" zsh -c "export init=1 && source ~/.zshrc && exit" # Install zsh plugins
  Info "Change default shell to $(which zsh)!"
}

# Install GNU/Linux system utilities
function InstallUtilies() {
  apt-get install -y tmux net-tools netcat vmtouch sysstat autossh
  Info "Install system utilies successfully!"
}

function InstallDocker() {
  # Don't install docker in docker!
  if [[ ${IsDocker} -eq 1 ]]; then
    Info "Detected running in docker. Skip docker installation."
    return 0
  fi
  local docker_repo="https://mirrors.aliyun.com" # Install docker via Alibaba mirror
  CheckCmd 'curl' 'sh' 'groupadd' 'usermod' 'getent'
  if ! type 'docker' &> /dev/null; then
    local distrname
    distrname="$(DistrName)"
    curl -fsSL "${docker_repo}"/docker-ce/linux/"${distrname}"/gpg | gpg --dearmor --batch --yes -o /usr/share/keyrings/docker-archive-keyring.gpg \
      && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] ${docker_repo}/docker-ce/linux/${distrname} $(lsb_release -cs) stable" \
      | tee /etc/apt/sources.list.d/docker.list > /dev/null \
      && apt-get update  && apt-get install -y docker-ce docker-ce-cli containerd.io
    # Add user to docker group
    set +e # Ignore error
    groupadd 'docker'
    usermod -aG 'docker' "${User}"
    set -e
    if ! getent group docker | grep -q "${User}"; then
      Fatal "Fail to add user ${User} to group docker"
    fi
  fi
  Info "Install docker successfully!"
}

function InstallGolang() {
  if ! type 'go' &> /dev/null && [[ ! -e '/usr/local/go/bin/go' ]]; then
    apt-get install -y axel tar \
      && axel -n8 "https://studygolang.com/dl/golang/${GolangFile}" -o "/tmp/${GolangFile}" \
      && tar -xzv -f "/tmp/${GolangFile}" -C /usr/local/ > /dev/null
  fi
  Info "Install Golang successfully!"
}

# Install neovim-nightly via neovim-nightly ppa
#
# NOTE: I am not sure it works in the furture.
function InstallNeovim() {
  # Debian: use old ubuntu version.
  # Ubuntu: use local ubuntu version.
  local distribution
  distribution="$(DistrName)"
  if [[ "${distribution,,}" == "ubuntu" ]]; then
    NeovimPPAUbuntuCode="$(UbuntuCode)"
  fi
  if ! type 'nvim' &> /dev/null; then
    apt-get update && apt-get install -y gnupg gpg software-properties-common \
      && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys  "${NeovimPpaKey}"\
      && echo -e "deb [arch=amd64] https://ppa.launchpadcontent.net/neovim-ppa/unstable/ubuntu ${NeovimPPAUbuntuCode} main
          deb-src [arch=amd64] https://ppa.launchpadcontent.net/neovim-ppa/unstable/ubuntu ${NeovimPPAUbuntuCode} main" > /etc/apt/sources.list.d/neovim-ppa.list \
      && apt-get update && apt-get -y install neovim
  fi
  Info "Install neovim-nightly successfully!"
}

#####################################################
# Main logic
#####################################################
function main() {
  # Exit when encounter error
  set -e
  set -o pipefail

  ConfigureEnv
  ConfigureTimeZone
  ConfigureApt
  ConfigureSsh

  InstallUtilies
  InstallGolang
  InstallDocker
  InstallNeovim
  InstallNvimConfig
  InstallDotfiles
  InstallZsh
  Info "Finish Installation!!!"
}

trap 'HandleErr "$?" "$LINENO"' ERR
trap 'GracefulExit' EXIT

main
