#!/bin/bash

set -exu

# Amazon Linux 2 system-release-cpe is:
# cpe:2.3:o:amazon:amazon_linux:2
# CentOS 7 system-release-cpe is:
# cpe:/o:centos:centos:7
# CentOS 6 system-release-cpe is:
# cpe:/o:centos:linux:6
# This means that column glitch exists.
# So, we should remove before "o" character.

distribution=$(cat /etc/system-release-cpe | awk '{print substr($0, index($1, "o"))}' | cut -d: -f2)
version=$(cat /etc/system-release-cpe | awk '{print substr($0, index($1, "o"))}' | cut -d: -f4)

ENABLE_UPGRADE_TEST=1
case ${distribution} in
  amazon)
    case ${version} in
      2)
        DNF=yum
        DISTRIBUTION_VERSION=${version}
        ;;
    esac
    ;;
  centos)
    case ${version} in
      7)
        DNF=yum
        DISTRIBUTION_VERSION=${version}
        ;;
      *)
        DNF="dnf --enablerepo=powertools"
        ENABLE_UPGRADE_TEST=0
        if [ x"${CENTOS_STREAM}" == x"true" ]; then
            echo "MIGRATE TO CENTOS STREAM"
            ${DNF} install centos-release-stream -y && \
                ${DNF} swap centos-{linux,stream}-repos -y && \
                ${DNF} distro-sync -y
            DISTRIBUTION_VERSION=${version}-stream
        else
            DISTRIBUTION_VERSION=${version}
        fi
        ;;
    esac
    ;;
esac

echo "INSTALL TEST"
repositories_dir=/fluentd/td-agent/yum/repositories
${DNF} install -y \
  ${repositories_dir}/${distribution}/${DISTRIBUTION_VERSION}/x86_64/Packages/*.rpm

td-agent --version

echo "UNINSTALL TEST"
${DNF} remove -y td-agent

conf_path=/etc/td-agent/td-agent.conf
if [ -e $conf_path ]; then
    echo "td-agent.conf must be removed: <${conf_path}>"
    exit 1
fi

if [ $ENABLE_UPGRADE_TEST -eq 1 ]; then
    echo "UPGRADE TEST from v3"
    rpm --import https://packages.treasuredata.com/GPG-KEY-td-agent
    case ${distribution} in
        amazon)
            cat >/etc/yum.repos.d/td.repo <<'EOF';
[treasuredata]
name=TreasureData
baseurl=https://packages.treasuredata.com/3/amazon/2/\$releasever/\$basearch
gpgcheck=1
gpgkey=https://packages.treasuredata.com/GPG-KEY-td-agent
EOF

            ;;
        *)
            cat >/etc/yum.repos.d/td.repo <<'EOF';
[treasuredata]
name=TreasureData
baseurl=https://packages.treasuredata.com/3/redhat/\$releasever/\$basearch
gpgcheck=1
gpgkey=https://packages.treasuredata.com/GPG-KEY-td-agent
EOF
            ;;
    esac
    ${DNF} update -y
    ${DNF} install -y td-agent
    ${DNF} install -y \
           ${repositories_dir}/${distribution}/${DISTRIBUTION_VERSION}/x86_64/Packages/*.rpm
fi
