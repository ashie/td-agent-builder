#!/bin/bash

set -exu

apt update
apt install -V -y lsb-release

. $(dirname $0)/commonvar.sh

apt install -V -y \
  ${repositories_dir}/${distribution}/pool/${code_name}/${channel}/*/*/*_${architecture}.deb

td-agent --version

apt remove -y td-agent

conf_path=/etc/td-agent/td-agent.conf
if [ ! -f $conf_path ]; then
    echo "td-agent.conf must be exist: <${conf_path}>"
    exit 1
fi
if [ ! -s $conf_path ]; then
    echo "td-agent.conf size must not be zero: <${conf_path}>"
    exit 1
fi

echo "td-agent-apt-source test"
apt_source_repositories_dir=/fluentd/td-agent-apt-source/apt/repositories
apt purge -y td-agent

conf_path=/etc/td-agent/td-agent.conf
if [ -e $conf_path ]; then
    echo "td-agent.conf must be purged: <${conf_path}>"
    exit 1
fi

apt clean all
apt_source_package=${apt_source_repositories_dir}/${distribution}/pool/${code_name}/${channel}/*/*/td-agent-apt-source*_all.deb
apt install -V -y ${apt_source_package}
apt update
apt install -V -y td-agent
