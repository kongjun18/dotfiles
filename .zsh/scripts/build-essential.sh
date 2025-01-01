#!/bin/bash
release="$(cat /etc/os-release | grep '^ID=' | cut -d = -f 2)"
if [[ "$release" == "debian" || "$release" == "ubuntu" ]]; then
    apt-get install -y build-essential libreadline-dev automake pkg-config
fi

