#!/bin/bash
#
# Configure development environment on local/remote new machine.
#
# Usage: system-bootstrap [-u <user>] [-p <port>] [-P <remote user password>] [-s <local/remote sudo password>] [-f <install.sh>] <host>
#     -u <user>                 user(default: local ${USER}) on remote machine.
#     -p <port>                 ssh port(default: 22).
#     -P <remote user password> password of user on remote machine.
#     -s <remote user password> sudo password on remote machine.
#                               If it is <-P> options is set but <-s> is not set,
#                               <remote user password> set to <remote user password>.
#     -f <install.sh>           installation script.
#     <host>                    local/remote machine name(ip).
#                               If <host> is empty, bootstrap the local machine!
#
# Steps:
# 1. Ensure ~/.ssh/id_ed25519 is available on your local machine.
# 2. Ensure you have sudo privilege on your local/remote machine.
# 3. Run this script according to the usage above.
#
# Examples:
# - Bootstrap debian in docker
#     ./system-bootstrap.sh -u user -p 222 -P user -s user localhost | tee /tmp/log
# - Bootstrap local debian machine
#     ./system-bootstrap.sh -s password localhost | tee /tmp/log
#
# Notes:
# - Need sudo privilege and will modify global environment.
# - Tested on Debian 11.3 and Ubuntu 18.04.
#
# Author: Kong Jun <kongjun18@outlook.com>
###############################################################################

#####################################################
# Script arguments
#####################################################
Host="" # bootstrap host
SshPort=22 # ssh port
User="${User}" # remote machine user
Password="" # remote account password
SudoPassword="" # remote sudo password
BootstrapSh="${HOME}/.zsh/scripts/bootstrap-debian.sh" # installation script

# Preserve HOME and USER environment!!!
Sudo="sudo --preserve-env={HOME,USER}"

#####################################################
# Argument parser
#####################################################
function Help() {
  echo "Usage: system-bootstrap [-u <user>] [-p <port>] [-P <remote user password>] [-s <local/remote sudo password>] [-f <install.sh>] <host>"
  echo "-u <user>                 user(default: local ${USER}) on remote machine."
  echo "-p <port>                 ssh port(default: 22)."
  echo "-P <remote user password> password of user on remote machine."
  echo "-s <remote user password> sudo password on remote machine."
  echo "                          If it is <-P> options is set but <-s> is not set,"
  echo "                          <remote user password> set to <remote user password>."
  echo "-f <install.sh>           installation script."
  echo "<host>                    local/remote machine name(ip)."
  echo "                          If <host> is empty, bootstrap the local machine!"
}

function ParseArgs() {
  while getopts "u:p:P:s:f:h" opt; do
    case "${opt}" in
      "u")
        User="${OPTARG}"
        ;;
      "p")
        SshPort="${OPTARG}"
        ;;
      "P")
        Password="${OPTARG}"
        ;;
      "s")
        SudoPassword="${OPTARG}"
        ;;
      "f")
        BootstrapSh="${OPTARG}"
        ;;
      "h")
        Help "$@"
        exit 0
        ;;
      *)
        Help "$@"
        exit 1
    esac
  done
  if [[ -n "${Password}" ]] && [[ -z "${SudoPassword}" ]]; then
    SudoPassword="${Password}"
  fi
  shift $((OPTIND-1))
  local args="$*"
  Host=${args[0]}
}

#####################################################
# Utilies
#####################################################
function Fatal() {
  local red='\e[1;31m'
  local reset='\e[0m'
  echo -e "${red}${1}${reset}" > /dev/stderr
}

function CheckCmd() {
  local error=0
  for exe in "$@"; do
    if ! type "${exe}" &> /dev/null; then
      Fatal "Please install ${exe} or update your path to include the ${exe} executable!"
      error=1
    fi
  done
  if [[ $error -eq 1 ]]; then
    exit 1
  fi
}

trap 'Fatal Error in line "${LINENO}' ERR

function Fatal() {
  local red='\e[1;31m'
  local reset='\e[0m'
  echo -e "${red}${1}${reset}" > /dev/stderr
}

function CheckCmd() {
  local error=0
  for exe in "$@"; do
    if ! type "${exe}" &> /dev/null; then
      Fatal "Please install ${exe} or update your path to include the ${exe} executable!"
      error=1
    fi
  done
  if [[ $error -eq 1 ]]; then
    exit 1
  fi
}

#####################################################
# Main logic
#####################################################
function main() {
  set -e
  set -o pipefail

  ParseArgs "$@"
  echo "####################################################"
  echo "Arguments:                                          "
  echo "    Host: ${Host}                                   "
  echo "    Port: ${SshPort}                                "
  echo "    User: ${User}                                   "
  echo "    Password: ${Password}                           "
  echo "    SudoPassword: ${SudoPassword}                   "
  echo "    InstallScript: ${BootstrapSh}                   "
  echo "####################################################"

  #####################################################
  # Bootstrap local machine
  #####################################################
  if [[ "${Host}" == "localhost" ]] \
    || [[ "${Host}" == "127.0.0.1" ]] \
    || [[ -z "${Host}" ]]
  then
    if [[ -n "${SudoPassword}" ]]; then
      eval "echo ${SudoPassword} | ${Sudo} -S bash ${BootstrapSh}"
    else
      eval "${Sudo} bash ${BootstrapSh}"
    fi
    exit
  fi

  #####################################################
  # Bootstrap remote machine
  #####################################################
  # Exit if there is no ssh utilies
  CheckCmd "ssh" "ssh-copy-id" "scp" "sshpass"
  if [[ ! -f "${HOME}/.ssh/id_ed25519.pub" ]] || [[ ! -f "${HOME}/.ssh/id_ed25519" ]]
  then
    Fatal "Please configure ssh public key"
  fi
  if [[ ! -d "${HOME}/.zsh/scripts" ]]; then
    Fatal "Please download kongjun18/dotfiles"
  fi

  local sshpass=""
  if [[ -n "${Password}" ]]; then
    sshpass="sshpass -p ${Password}"
  fi
  local ssh="${sshpass} ssh -q -t -p ${SshPort} ${User}@${Host}"
  local ssh_copy_id="${sshpass} ssh-copy-id -p ${SshPort} ${User}@${Host}"
  local scp="${sshpass} scp -P ${SshPort:-22}"
  echo "${User:-${USER}}"

  local date
  date="$(date +%Y-%m-%d)"
  local backup_ssh="\"bash -c 'mkdir -p /home/${User}/.ssh-${date} && cp /home/${User}/.ssh/.id_* /home/${User}/.ssh-${date}/' &> /dev/null\""
  local restore_ssh="\"bash -c 'cp /home/${User}/.ssh-${date}/* /home/${User}/.ssh/' &> /dev/null \""

  eval "${ssh_copy_id}"
  eval "${ssh} ${backup_ssh} || true"
  eval "${scp} -r ~/.ssh/id_ed25519{,.pub} ${User}@${Host}:.ssh/" # Copy local ssh key to remote machine.
  eval "${scp} ${BootstrapSh} ${User}@${Host}:/tmp/${BootstrapSh}"
  eval "${ssh} 'echo ${SudoPassword} | ${Sudo} bash /tmp/${BootstrapSh}; rm /tmp/${BootstrapSh}'"
  eval "${ssh} ${restore_ssh} || true"
}

main "$@"
