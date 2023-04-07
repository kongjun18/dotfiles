#!/bin/bash
###############################################################################
# Configure development environment on local/remote new machine.
#
# Usage: system-bootstrap [-u <user>] [-p <port>] [-P <remote user password>] [-s <local/remote sudo password>] [-f <install.sh>] <host>
#     -u <user>                 user(default: local ${USER}) on remote machine.
#     -p <port>                 ssh port(default: 22).
#     -P <remote user password> password of user on remote machine.
#     -s <remote sudo password> sudo password on remote machine.
#                               If it is '-P' options is set but '-s' is not set,
#                               <remote sudo password> set to <remote user password>.
#     -f <bootstrap.sh>         bootstrap script.
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
#     ./system-bootstrap.sh -u user -p 222 -P password -s password -f bootstrap.sh localhost | tee /tmp/log
# - Bootstrap local debian machine
#     ./system-bootstrap.sh -s password -f bootstrap.sh localhost | tee /tmp/log
#
# Notes:
# - Need sudo privilege and will modify global environment.
# - Tested on Debian 11.3 and Ubuntu 18.04.
# - Old .ssh directory is backuped in ~/.ssh-$(date +%Y-%m-%d-%k-%m-%S).
# - Log is located in ~/.bootstrap-$(date +%Y-%m-%d-%k-%m-%S).log
#
# Implementation notes:
#
# Author: Kong Jun <kongjun18@outlook.com>
###############################################################################

#####################################################
# Script arguments
#####################################################
Host="" # bootstrap host
SshPort=22 # ssh port
User="${USER}" # remote machine user
Password="" # remote account password
SudoPassword="" # remote sudo password
BootstrapSh=""
# Preserve HOME and USER environment!!!
Sudo="sudo --preserve-env={HOME,USER}"

#####################################################
# Argument parser
#####################################################
function Help() {
echo -e 'Configure development environment on local/remote new machine.\n'

echo -e 'Usage: system-bootstrap [-u <user>] [-p <port>] [-P <remote user password>] [-s <local/remote sudo password>] [-f <install.sh>] <host>\n'
echo -e '-u <user>                 user(default: local ${USER}) on remote machine.\n'
echo -e '-p <port>                 ssh port(default: 22).\n'
echo -e '-P <remote user password> password of user on remote machine.\n'
echo -e '-s <remote sudo password> sudo password on remote machine.\n'
echo -e '                          If it is '-P' options is set but '-s' is not set,\n'
echo -e '                          <remote sudo password> set to <remote user password>.\n'
echo -e '-f <bootstrap.sh>         bootstrap script.\n'
echo -e '<host>                    local/remote machine name(ip).\n'
echo -e '                          If <host> is empty, bootstrap the local machine!\n'
echo -e '\n'
echo -e 'Steps:\n'
echo -e '1. Ensure ~/.ssh/id_ed25519 is available on your local machine.\n'
echo -e '2. Ensure you have sudo privilege on your local/remote machine.\n'
echo -e '3. Run this script according to the usage above.\n'
echo -e '\n'
echo -e 'Examples:\n'
echo -e '- Bootstrap debian in docker\n'
echo -e '    ./system-bootstrap.sh -u user -p 222 -P password -s password -f bootstrap.sh localhost | tee /tmp/log\n'
echo -e '- Bootstrap local debian machine\n'
echo -e '    ./system-bootstrap.sh -s password -f bootstrap.sh localhost | tee /tmp/log\n'
echo -e '\n'
echo -e 'Notes:\n'
echo -e '- Need sudo privilege and will modify global environment.\n'
echo -e '- Tested on Debian 11.3 and Ubuntu 18.04.\n'
echo -e '\n'
echo -e 'Author: Kong Jun <kongjun18@outlook.com>\n'
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

# Print error message to stderr.
function Fatal() {
  local red='\e[1;31m'
  local reset='\e[0m'
  echo -e "${red}${1}${reset}" > /dev/stderr
}

# Check commands. Exit script if failed.
#
# Arguments:
#   An array of command
#
# Outputs:
#   Writes error message to stderr
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
  trap 'Fatal "Error in line ${LINENO}"' ERR
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
  echo "    BootstrapSh: ${BootstrapSh}                     "
  echo "####################################################"

  if [[ -z "${Password}" ]]; then
    Fatal "Please set password!"
  fi
  if [[ -z "${BootstrapSh}" ]]; then
    Fatal "Please set bootstrap script!"
    exit 1
  fi
  if [[ ! -f "${BootstrapSh}" ]]; then
    Fatal "Please set correct bootstrap script!"
    exit 1
  fi

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

  local sshpass="sshpass -p ${Password}"
  # NOTE:
  # - sshpass is used to automate passward auth.
  # - ssh option 'StrictHostKeyChecking=no' is used to avoid ask 'yes or no'.
  local ssh="${sshpass} ssh -o StrictHostKeyChecking=no -q -t -p ${SshPort} ${User}@${Host}"
  # ssh-copy-id in force mode.
  # Copy keys without trying to check if they are already installed.
  local ssh_copy_id="${sshpass} ssh-copy-id -o StrictHostKeyChecking=no -f -p ${SshPort} ${User}@${Host}"
  local scp="${sshpass} scp -P ${SshPort:-22}"

  local now
  now="$(date +%Y-%m-%d-%k-%m-%S)"
  local backup_ssh="\"bash -c 'mkdir -p /home/${User}/.ssh-${now} && cp /home/${User}/.ssh/.id_* /home/${User}/.ssh-${now}/' &> /dev/null\""
  local restore_ssh="\"bash -c 'cp /home/${User}/.ssh-${now}/* /home/${User}/.ssh/' &> /dev/null \""

  eval "${ssh_copy_id}"
  eval "${ssh} ${backup_ssh} || true"
  eval "${scp} -r ~/.ssh/id_ed25519{,.pub} ${User}@${Host}:.ssh/" # Copy local ssh key to remote machine.
  local bootstrapsh_basename
  bootstrapsh_basename="$(basename "${BootstrapSh}")"
  eval "${scp} ${BootstrapSh} ${User}@${Host}:/tmp/${bootstrapsh_basename}"
  eval "${ssh} 'echo ${SudoPassword} | ${Sudo} -S bash /tmp/${bootstrapsh_basename} 2>&1 | tee /home/${User}/.bootstrap-${now}.log; rm /tmp/${bootstrapsh_basename}'"
  eval "${ssh} ${restore_ssh} || true"
}

main "$@"
