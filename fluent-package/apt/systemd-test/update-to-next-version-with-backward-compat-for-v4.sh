#!/bin/bash

set -exu

. $(dirname $0)/../commonvar.sh

# TODO: Remove it when v5 repository was deployed
sudo apt install -y curl ca-certificates
curl -O https://packages.treasuredata.com/4/${distribution}/${code_name}/pool/contrib/f/fluentd-apt-source/fluentd-apt-source_2020.8.25-1_all.deb
sudo apt install -y ./fluentd-apt-source_2020.8.25-1_all.deb

# Install v4
sudo apt clean all
# Uncomment when v5 repository was deployed
#apt_source_package=/vagrant/${distribution}/pool/${code_name}/${channel}/*/*/fluent-apt-source*_all.deb
#sudo apt install -V -y ${apt_source_package} ca-certificates
sudo apt update
sudo apt install -V -y td-agent=4.5.0-1

systemctl status --no-pager td-agent

# Install the current
sudo apt install -V -y \
    /vagrant/${distribution}/pool/${code_name}/${channel}/*/*/fluent-package_*_${architecture}.deb
systemctl status --no-pager fluentd

sudo systemctl stop fluentd
sudo systemctl unmask td-agent
sudo systemctl enable --now fluentd

systemctl status --no-pager fluentd
systemctl status --no-pager td-agent

# Make a dummy pacakge for the next version
dpkg-deb -R /vagrant/${distribution}/pool/${code_name}/${channel}/*/*/fluent-package_*_${architecture}.deb tmp
last_ver=$(cat tmp/DEBIAN/control | grep "Version: " | sed -E "s/Version: ([0-9.]+)-([0-9]+)/\2/g")
sed -i -E "s/Version: ([0-9.]+)-([0-9]+)/Version: \1-$(($last_ver+1))/g" tmp/DEBIAN/control
dpkg-deb --build tmp next_version.deb

# Install the dummy package
sudo apt install -V -y ./next_version.deb

# Test: service
systemctl status --no-pager fluentd
systemctl status --no-pager td-agent

# Test: keep compatibility with v4: symlinks for config files
test -h /etc/td-agent
test -h /etc/fluent/fluentd.conf
test $(readlink "/etc/fluent/fluentd.conf") = "/etc/fluent/td-agent.conf"
test -e /etc/td-agent/td-agent.conf

# Test: keep compatibility with v4: symlinks for log files
test -h /var/log/td-agent

# Test: keep compatibility with v4: symlinks for bin files
test -h /usr/sbin/td-agent
test -h /usr/sbin/td-agent-gem

# Test: No error logs
# (v4 default config outputs 'warn' log, so we should check only 'error' and 'fatal' logs)
sleep 3
test -e /var/log/fluent/fluentd.log
(! grep -e '\[error\]' -e '\[fatal\]' /var/log/fluent/fluentd.log)

# Uninstall
sudo apt remove -y fluent-package
(! systemctl status --no-pager td-agent)
(! systemctl status --no-pager fluentd)
