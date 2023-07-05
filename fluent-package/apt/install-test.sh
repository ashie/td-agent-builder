#!/bin/bash

set -exu

apt update
apt install -V -y lsb-release

. $(dirname $0)/commonvar.sh

apt install -V -y \
  ${repositories_dir}/${distribution}/pool/${code_name}/${channel}/*/*/*_${architecture}.deb

td-agent --version

apt remove -y fluent-package


if ! getent passwd _fluentd >/dev/null; then
    echo "_fluentd user must be kept"
    exit 1
fi

if ! getent group _fluentd >/dev/null; then
    echo "_fluentd group must be kept"
    exit 1
fi

echo "fluentd-apt-source test"
apt_source_repositories_dir=/fluentd/fluentd-apt-source/apt/repositories
apt purge -y fluent-package

for conf_path in /etc/td-agent/td-agent.conf /etc/fluent/fluentd.conf; do
    if [ -e $conf_path ]; then
	echo "$conf_path must be removed"
	exit 1
    fi
done

# TODO: Remove it when v5 repository was deployed
apt install -y curl
curl -O https://packages.treasuredata.com/4/${distribution}/${code_name}/pool/contrib/f/fluentd-apt-source/fluentd-apt-source_2020.8.25-1_all.deb
apt install -y ./fluentd-apt-source_2020.8.25-1_all.deb

if [ ${code_name} = "jammy" ]; then
    # TODO: Remove when repository for jammy has been deployed
    echo "skip to install via apt repository: <${code_name}>"
    exit 0
fi
apt clean all
# Uncomment when v5 repository was deployed
#apt_source_package=${apt_source_repositories_dir}/${distribution}/pool/${code_name}/${channel}/*/*/fluentd-apt-source*_all.deb
#apt install -V -y ${apt_source_package} ca-certificates
apt update
apt install -V -y td-agent

apt install -V -y \
  ${repositories_dir}/${distribution}/pool/${code_name}/${channel}/*/*/*_${architecture}.deb


if ! getent passwd td-agent >/dev/null; then
    echo "td-agent user must exist"
    exit 1
fi

if ! getent group td-agent >/dev/null; then
    echo "td-agent group must exist"
    exit 1
fi

if ! getent passwd _fluentd >/dev/null; then
    echo "_fluentd user must exist"
    exit 1
fi

if ! getent group _fluentd >/dev/null; then
    echo "_fluentd group must exist"
    exit 1
fi

if [ ! -h /var/log/td-agent ]; then
    echo "/var/log/td-agent must be symlink"
    exit 1
fi
if [ ! -h /etc/td-agent ]; then
    echo "/etc/td-agent must be symlink"
    exit 1
fi

# Note: As td-agent and _fluentd use same UID/GID,
# it is regarded as preceding name (td-agent)
owner=$(stat --format "%U/%G" /etc/fluent)
if [ "$owner" != "td-agent/td-agent" ]; then
    echo "/etc/fluent must be owned by td-agent/td-agent"
    exit 1
fi
owner=$(stat --format "%U/%G" /var/log/fluent)
if [ "$owner" != "td-agent/td-agent" ]; then
    echo "/var/log/fluent must be owned by td-agent/td-agent"
    exit 1
fi
owner=$(stat --format "%U/%G" /var/run/fluent)
if [ "$owner" != "td-agent/td-agent" ]; then
    echo "/var/run/fluent must be owned by td-agent/td-agent"
    exit 1
fi


