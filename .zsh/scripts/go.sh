#!/bin/zsh

# 检查 wget 或 curl 是否已安装
if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
  echo "wget 或 curl 必须安装一个"
  exit 1
fi

# 查找最新版本
ARCH=$(uname -m)
case "${ARCH}"; in
    x86_64)
        ARCH="amd64";;
    aarch64)
        ARCH="arm64";;
    *)
    ARCH="unknown"
esac

case "${MACHINE}" in
    Linux) OS="linux";;
    Mac)   OS="mac";;
    *)     OS="UNKNOWN:${unameOut}"
esac

echo "Finding latest version of Go for ${OS}-${ARCH}..."
DL_HOME=https://golang.org
DL_PATH_URL="$(wget --no-check-certificate -qO- https://golang.org/dl/ | grep -oP "\/dl\/go([0-9\.]+)\.$OS-${ARCH}\.tar\.gz" | head -n 1)"
GO_VERSION="$(echo $DL_PATH_URL | grep -oP 'go[0-9\.]+' | grep -oP '[0-9\.]+' | head -c -2 )"
GO_TARBALL="go${GO_VERSION}.${OS}-${ARCH}.tar.gz"
GO_URL="https://golang.org/dl/${GO_TARBALL}"

# 下载 Go tar 包
mkdir -p "${GOPATH}"
echo "正在下载 Go ${GO_VERSION}..."
trap 'echo "删除 $GOPATH/$GO_TARBALL"; rm -rf "$GOPATH/$GO_TARBALL"' EXIT
if command -v wget >/dev/null 2>&1; then
  wget $GO_URL -O $GOPATH/$GO_TARBALL
else
  curl -o $GOPATH/$GO_TARBALL $GO_URL
fi

# 检查下载是否成功
if [ ! -f $GOPATH/$GO_TARBALL ]; then
  echo "Go ${GO_VERSION} 下载失败"
  exit 1
fi

# 解压 Go tar 包
echo "正在解压 Go ${GO_VERSION}..."
tar -C "$GOPATH" -xzf ${GOPATH}/${GO_TARBALL}

# 检查解压是否成功
if [ ! -d $GOROOT ]; then
  echo "Go ${GO_VERSION} 解压失败"
  exit 1
fi

echo "验证 Go 安装..."
go version

echo "Go ${GO_VERSION} 安装完成！"
