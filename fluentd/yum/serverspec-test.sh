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

ENABLE_SERVERSPEC_TEST=1
ENABLE_KAFKA_TEST=1
JAVA_JRE=java-11-openjdk
N_POLLING=30
case ${distribution} in
  amazon)
    case ${version} in
      2)
        DNF=yum
        ENABLE_SERVERSPEC_TEST=0
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

if [ $ENABLE_SERVERSPEC_TEST -eq 1 ]; then
    ${DNF} install -y curl which ${repositories_dir}/${distribution}/${DISTRIBUTION_VERSION}/x86_64/Packages/*.rpm

    /usr/sbin/td-agent-gem install --no-document serverspec
    if [ $ENABLE_KAFKA_TEST -eq 1 ]; then
        rpm --import https://packages.confluent.io/rpm/6.0/archive.key

        cat >/etc/yum.repos.d/confluent.repo <<EOF;
[Confluent.dist]
name=Confluent repository (dist)
baseurl=https://packages.confluent.io/rpm/6.0/${version}
gpgcheck=1
gpgkey=https://packages.confluent.io/rpm/6.0/archive.key
enabled=1

[Confluent]
name=Confluent repository
baseurl=https://packages.confluent.io/rpm/6.0
gpgcheck=1
gpgkey=https://packages.confluent.io/rpm/6.0/archive.key
enabled=1
EOF
	yum update -y && yum install -y confluent-community-2.13 ${JAVA_JRE} nc
	export KAFKA_OPTS=-Dzookeeper.4lw.commands.whitelist=ruok
	/usr/bin/zookeeper-server-start /etc/kafka/zookeeper.properties  &
	n=1
        while true ; do
	    sleep 1
	    status=$(echo ruok | nc localhost 2181)
	    if [ "$status" = "imok" ]; then
		break
	    fi
            n=$((n + 1))
	    if [ $n -ge $N_POLLING ]; then
		echo "failed to get response from zookeeper-server"
		exit 1
	    fi
	done
	/usr/bin/kafka-server-start /etc/kafka/server.properties &
	n=1
	while true ; do
	    sleep 1
	    status=$(/usr/bin/zookeeper-shell localhost:2181 ls /brokers/ids | sed -n 6p)
	    if [ "$status" = "[0]" ]; then
		break
	    fi
            n=$((n + 1))
	    if [ $n -ge $N_POLLING ]; then
		echo "failed to get response from kafka-server"
		exit 1
	    fi
	done
	/usr/bin/kafka-topics --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic test
	/usr/sbin/td-agent -c /fluentd/serverspec/test.conf &
    fi
    export PATH=/opt/td-agent/bin:$PATH
    export INSTALLATION_TEST=true
    cd /fluentd && rake serverspec:linux
fi
