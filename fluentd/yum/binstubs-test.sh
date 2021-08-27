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

repositories_dir=/fluentd/td-agent/yum/repositories
ARCH=$(rpm --eval "%{_arch}")
${DNF} install -y \
  ${repositories_dir}/${distribution}/${DISTRIBUTION_VERSION}/${ARCH}/Packages/*.rpm

echo "BINSTUBS TEST"
/opt/td-agent/bin/ruby /fluentd/td-agent/binstubs-test.rb
if [ $? -eq 0 ]; then
    echo "Checking existence of binstubs: OK"
else
    echo "Checking existence of binstubs: NG"
    exit 1
fi
