#!/bin/bash

set -exu

. $(dirname $0)/../commonvar.sh

# Install the current
sudo apt install -V -y \
    /host/${distribution}/pool/${code_name}/${channel}/*/*/fluent-package_*_${architecture}.deb

# Make a dummy pacakge for the next version
dpkg-deb -R /host/${distribution}/pool/${code_name}/${channel}/*/*/fluent-package_*_${architecture}.deb tmp
last_ver=$(cat tmp/DEBIAN/control | grep "Version: " | sed -E "s/Version: ([0-9.]+)-([0-9]+)/\2/g")
sed -i -E "s/Version: ([0-9.]+)-([0-9]+)/Version: \1-$(($last_ver+1))/g" tmp/DEBIAN/control
# Bump up x.y.w.z to check whether FLUENT_PACKAGE_VERSION was updated correctly later
sed -i -E "s/FLUENT_PACKAGE_VERSION=([0-9.]+)/FLUENT_PACKAGE_VERSION=\1.1/g" tmp/lib/systemd/system/fluentd.service
next_package_ver=$(cat tmp/lib/systemd/system/fluentd.service | grep "FLUENT_PACKAGE_VERSION" | sed -E "s/Environment=FLUENT_PACKAGE_VERSION=(.+)/\1/")
echo "repacked next fluent-package version: $next_package_ver"
dpkg-deb --build tmp next_version.deb

# Install the dummy package
sudo apt install -V -y ./next_version.deb

# Test: service
systemctl status --no-pager fluentd

# Test: migration process from v4 must not be done
(! test -e /etc/td-agent)
(! test -e /etc/fluent/td-agent.conf)
(! test -e /var/log/td-agent)
(! test -e /var/log/fluent/td-agent.log)
(! test -h /usr/sbin/td-agent)
(! test -h /usr/sbin/td-agent-gem)

# Test: environmental variables
pid=$(systemctl show fluentd --property=MainPID --value)
env_vars=$(sudo sed -e 's/\x0/\n/g' /proc/$pid/environ)
test $(eval $env_vars && echo $HOME) = "/var/lib/fluent"
test $(eval $env_vars && echo $LOGNAME) = "_fluentd"
test $(eval $env_vars && echo $USER) = "_fluentd"
test $(eval $env_vars && echo $FLUENT_CONF) = "/etc/fluent/fluentd.conf"
test $(eval $env_vars && echo $FLUENT_PACKAGE_LOG_FILE) = "/var/log/fluent/fluentd.log"
test $(eval $env_vars && echo $FLUENT_PLUGIN) = "/etc/fluent/plugin"
test $(eval $env_vars && echo $FLUENT_SOCKET) = "/var/run/fluent/fluentd.sock"
# FLUENT_PACKAGE_VERSION will be updated after the next restart
(! test $(eval $env_vars && echo $FLUENT_PACKAGE_VERSION) = "$next_package_ver")

# Test: fluent-diagtool
sudo fluent-gem install fluent-plugin-concat
/opt/fluent/bin/fluent-diagtool -t fluentd -o /tmp
test $(find /tmp/ -name gem_local_list.output | xargs cat) = "fluent-plugin-concat"

# Test: logs
sleep 3
test -e /var/log/fluent/fluentd.log
(! grep -q -e '\[warn\]' -e '\[error\]' -e '\[fatal\]' /var/log/fluent/fluentd.log)

# Test: Guard duplicated instance
(! sudo /usr/sbin/fluentd)
(! sudo /usr/sbin/td-agent)
(! sudo /usr/sbin/fluentd -v)
sudo /usr/sbin/fluentd --dry-run

# Uninstall
sudo apt remove -y fluent-package
(! systemctl status --no-pager td-agent)
(! systemctl status --no-pager fluentd)
