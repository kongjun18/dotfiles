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

# Git: git@github.com:
# HTTPS: https://github.com/
readonly GitHubMirror=https://github.com/

readonly YadmRepo="${HOME}/.local/share/yadm/repo.git"

# Neovim-nightly PPA Ubuntu version
NeovimPPAUbuntuCode="bionic"

# Neovim-nightly PPA signing key.
# See https://launchpad.net/~neovim-ppa/+archive/ubuntu/unstable.
readonly NeovimPpaKey="9DBB0BE9366964F134855E2255F96FCF8231B6DD"

readonly GolangFile="go1.20.5.linux-amd64.tar.gz"
# Standard GOROOT: /usr/local/go
readonly GOROOT="${HOME}/.go/go"

#####################################################
# Utilies
#####################################################
function VersionLessOrEqual() {
    [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

function VersionLess() {
    [ "$1" = "$2" ] && return 1 || verlte $1 $2
}

# Print error and exit
function Fatal() {
  local red='\e[1;31m'
  local reset='\e[0m'
  echo -e "${red}ERROR: ${*}${reset}" > /dev/stderr
  exit 1
}

function Info() {
  local green='\e[1;32m'
  local reset='\e[0m'
  echo -e "${green}INFO: ${*}${reset}"
}

# Exit if cmd not exists
function CheckCmd() {
  for exe in "$@"; do
    if ! type "${exe}" &> /dev/null; then
      Fatal "Please install ${exe} or update your path to include the ${exe} executable!"
    fi
  done
}

# Check if a path is in home directory.
function HomePath() {
  [[ $(echo "$1" | cut -d '/' -f 2) == "home" ]]
}

function ConfigureEnv() {
  User="$(basename "$HOME")" # NOTE: Debian $USER is empty in docker build stage!
  IsDocker=0
  ResourceCleared=0
  if [[ -e /.dockerenv ]]; then
    IsDocker=1
  fi
  unameOut="$(uname -s)"
  case "${unameOut}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    CYGWIN*)    MACHINE=Cygwin;;
    MINGW*)     MACHINE=MinGw;;
    MSYS_NT*)   MACHINE=Git;;
    *)          MACHINE="UNKNOWN:${unameOut}"
  esac
  if [[ "${MACHINE}" == "Linux" ]]; then
    dist="$(awk -F '=' '$1 ~ /^ID$/ {print $2}' /etc/os-release)"
    case "${dist}" in
        ubuntu|Ubuntu)
            LINUXDIST=Ubuntu
            CODENAME="$(awk -F'=' '$1~/UBUNTU_CODENAME/ {print $2}' /etc/os-release)"
            VERSION="$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2)"
            ;;
        debian|Debian)
            LINUXDIST=Debian
            CODENAME="$(awk '{print $2}' /etc/os-release | grep -o '(.*)' | cut -d '(' -f 2 | cut -d ')' -f 1)"
            VERSION="$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2)"
            ;;
        *)             LINUXDIST="UNKNOWN:${dist}"
    esac
  fi
  echo "MACHINE: ${MACHINE}"
  if [[ "${MACHINE}" == "Linux" ]]; then
      echo "LINUX DISTRIBUTION: ${LINUXDIST}"
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

# Generate Debian/Ubuntu /etc/apt/source.list
function GenerateAPTSourceList() {
    if [[ "$MACHINE" == "Linux" ]]; then
        case "${LINUXDIST}" in
        Ubuntu)
            echo -e "deb http://${OpenSourceMirror}/ubuntu/ ${CODENAME} main restricted universe multiverse
            deb-src http://${OpenSourceMirror}/ubuntu/ ${CODENAME} main restricted universe multiverse
            deb http://${OpenSourceMirror}/ubuntu/ ${CODENAME}-security main restricted universe multiverse
            deb-src http://${OpenSourceMirror}/ubuntu/ ${CODENAME}-security main restricted universe multiverse
            deb http://${OpenSourceMirror}/ubuntu/ ${CODENAME}-updates main restricted universe multiverse
            deb-src http://${OpenSourceMirror}/ubuntu/ ${CODENAME}-updates main restricted universe multiverse
            deb http://${OpenSourceMirror}/ubuntu/ ${CODENAME}-backports main restricted universe multiverse
            deb-src http://${OpenSourceMirror}/ubuntu/ ${CODENAME}-backports main restricted universe multiverse" > /etc/apt/sources.list
            ;;
        Debian)
            echo -e "deb http://${OpenSourceMirror}/debian/ ${CODENAME} main contrib non-free
            # deb-src http://${OpenSourceMirror}/debian/ ${CODENAME} main contrib non-free
            deb http://${OpenSourceMirror}/debian/ ${CODENAME}-updates main contrib non-free
            # deb-src http://${OpenSourceMirror}/debian/ ${CODENAME}-updates main contrib non-free
            deb http://${OpenSourceMirror}/debian/ ${CODENAME}-backports main contrib non-free
            # deb-src http://${OpenSourceMirror}/debian/ ${CODENAME}-backports main contrib non-free
            deb http://${OpenSourceMirror}/debian-security ${CODENAME}-security main contrib non-free
            # deb-src http://${OpenSourceMirror}/debian-security ${CODENAME}-security main contrib non-free" > /etc/apt/sources.list
            ;;
        *)
          Fatal "Unsupported Platform ${LINUXDIST}"
          ;;
      esac
    fi
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
function UpperUserChown() {
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
  UpperUserChown "$@"
}

# mkdir wrapper which create directories whose owner/group is ${User} .
function UserMkdir() {
  mkdir -p "$@"
  UpperUserChown "$@"
}

#####################################################
# Installer
#####################################################

# NOTE: Old yadm uses 'master' as default branch and stores repo into ~/.config/yadm/repo.git.
# Thus it is necessary to set flags explicitly.
yadm="yadm --yadm-repo ${YadmRepo}"
# yadm clone wrapper which inputs "yes" automatically
function YadmClone() {
  CheckCmd 'expect'
  expect <<EOF
set timeout 60
spawn ${yadm} clone $*
expect {
  "continue connecting (yes/no" { send "yes\r"; exp_continue }
  eof
}
EOF
}

# Clone and configurate dotfiles git repo
function InstallDotfiles() {
  apt-get update -y && apt-get install -y zsh fzy lua5.1 yadm
  ${yadm} config yadm.auto-private-dirs false
  if [ -d "${YadmRepo}" ]; then
    Info "Dotfiles exists"
    Info "It is unnessary to clone dotfiles"
    return 0
  else
    # All existed files will be stashed. Use 'yadm stash list' to see them.
    YadmClone -f -b main "${GitHubMirror}kongjun18/dotfiles.git"
  fi

  RecursiveUserChown "${YadmRepo}"
  for file in $(${yadm} ls-files); do
      RecursiveUserChown "${file}"
  done

  Info "Install kongjun18/dotfiles successfully!"
}

function InstallNvimConfig() {
  [[ -d "${HOME}/.config/nvim" ]] && Info "Neovim configuration exists"
  GitClone "${GitHubMirror}kongjun18/nvim.git" ~/.config/nvim \
    && RecursiveUserChown ~/.config/nvim
  if [[ -d ~/.local/nvim ]];then
    RecursiveUserChown ~/.local/nvim
  fi
  if [[ -d ~/.cache ]];then
    RecursiveUserChown ~/.cache
  fi
  Info "Install neovim configuration successfully!"
}

# Configure time zone to avoid inputting timezone manually when configure tzdata.
function ConfigureTimeZone() {
  if [[ ! -e /etc/localtime ]]; then
    ln -snf /usr/share/zoneinfo/"$TimeZone" /etc/localtime \
    && echo "$TimeZone" > /etc/timezone
  fi
}

# Configure apt and install necessary utilities
function ConfigureAPT() {
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

function ConfigureSSH() {
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
  type zsh &> /dev/null &&
  apt-get -y install zsh\
    build-essential # Some zsh plugins needed to be compiled
    if [[ "$MACHINE" == "Linux" ]] && [[ "$LINUXDIST" == "Ubuntu" ]] && VersionLessOrEqual "${VERSION}" 20.04; then
        apt-get -y install bsdmainutils
    fi
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
  set +e
  if type 'go' &> /dev/null || [[ -e "${GOROOT}" ]]; then
    local existed="yes"
  fi
  set -e
  if [[ -n "${existed}" ]]; then
    Info "Go exists."
    return 0
  fi
  apt-get install -y axel tar \
    && axel -n8 "https://studygolang.com/dl/golang/${GolangFile}" -o "/tmp/${GolangFile}" \
    && mkdir -p "${GOROOT}" \
    && tar -xzv -f "/tmp/${GolangFile}" -C "${GOROOT}" > /dev/null
  # Correct user group
  if HomePath "$(realpath "${GOROOT}")"; then
    RecursiveUserChown "${GOROOT}"
  fi
  Info "Install Golang successfully!"
}

# Install neovim-nightly via neovim-nightly ppa
#
# NOTE: I am not sure it works in the furture.
function InstallNeovimPPA() {
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

function InstallNeovim() {
    apt-get install -y fuse libfuse2 \
    && mkdir -p ~/.bin \
    && curl -L https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage -o ~/.bin/nvim \
    && chmod u+x ~/.bin/nvim
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
  GenerateAPTSourceList
  ConfigureAPT
  # ConfigureSSH

  InstallUtilies

  InstallGolang
  InstallDocker
  # InstallNeovimPPA
  InstallNeovim
  InstallNvimConfig
  InstallDotfiles
  InstallZsh
  Info "Finish Installation!!!"
}

trap 'HandleErr "$?" "$LINENO"' ERR
trap 'GracefulExit' EXIT

main
