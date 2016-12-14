#!/bin/bash
# authro: PADDLE QA TEAM

function init_env() {
    apt-get update && apt-get install -y \
        openssh-server \
        vim \
        libjpeg-dev \
        && rm -rf /var/lib/apt/lists/*
    mkdir /var/run/sshd
    echo 'root:root' | chpasswd
    sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
    pip install pillow
    pip install matplotlib
    mkdir /root/auto_test
}

init_env
