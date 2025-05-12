#!/bin/bash

set -euo pipefail

install_from_golang_website() {
  echo "Finding latest version of Go for ${OS}-${ARCH}..."
  DL_PATH_URL="$(wget --no-check-certificate -qO- https://golang.org/dl/ | grep -oP "\/dl\/go([0-9\.]+)\.$OS-${ARCH}\.tar\.gz" | head -n 1)"
  GO_VERSION="$(echo "$DL_PATH_URL" | grep -oP 'go[0-9\.]+' | grep -oP '[0-9\.]+' | head -c -2 )"
  GO_TARBALL="go${GO_VERSION}.${OS}-${ARCH}.tar.gz"
  GO_URL="https://golang.org/dl/${GO_TARBALL}"

  mkdir -p "${GOPATH}"
  echo "Download Go ${GO_VERSION}"
  trap 'echo "Delete $GOPATH/$GO_TARBALL"; rm -rf "$GOPATH/$GO_TARBALL"' EXIT
  if command -v wget >/dev/null 2>&1; then
    wget "$GO_URL" -O "$GOPATH/$GO_TARBALL"
  else
    curl -o "$GOPATH/$GO_TARBALL" "$GO_URL"
  fi

  if [ ! -f "$GOPATH/$GO_TARBALL" ]; then
    echo "ERRORLL Failed to download go ${GO_VERSION}"
    exit 1
  fi

  echo "Extract go ${GO_VERSION}..."
  tar -C "$GOPATH" -xzf "${GOPATH}/${GO_TARBALL}"

  if [ ! -d "$GOROOT" ]; then
    echo "ERRORLL Failed to extract go ${GO_VERSION}"
    exit 1
  fi

  go version
}

install_from_pacman() {
  pacman -S --noconfirm mingw-w64-x86_64-go
}

if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: $0 needs wget or curl to be installed"
  exit 1
fi

ARCH=$(uname -m)
case "${ARCH}" in
    x86_64)
        ARCH="amd64";;
    aarch64)
        ARCH="arm64";;
    *)
    ARCH="unknown"
esac

unameOut="$(uname -o)"
export MACHINE
export ARCH
case "${unameOut}" in
    *Linux*)
        MACHINE=Linux
        export LINUX_RELEASE
        LINUX_RELEASE="$(grep '^ID=' /etc/os-release | cut -d = -f 2)"
        ;;
    Darwin*)    MACHINE=Mac;;
    Msys)       MACHINE=MSYS;;
    *)          MACHINE="UNKNOWN:${unameOut}"
esac

case "${MACHINE}" in
    Linux) OS="linux";;
    Mac)   OS="mac";;
    MSYS)  ;;
    *)     OS="UNKNOWN:${unameOut}"
    echo "ERROR: $0 does not support ${MACHINE}"
    exit 1
esac

if [[ "$MACHINE" == MSYS ]]; then
  install_from_pacman
else
  install_from_golang_website
fi
