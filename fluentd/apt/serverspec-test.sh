#!/bin/bash

set -exu

export DEBIAN_FRONTEND=noninteractive

apt update
apt install -V -y lsb-release

. $(dirname $0)/commonvar.sh

apt install -V -y \
  ${repositories_dir}/${distribution}/pool/${code_name}/${channel}/*/*/*_${architecture}.deb

td-agent --version

case ${code_name} in
    xenial)
	apt install -V -y gnupg2 wget apt-transport-https
	;;
    *)
	apt install -V -y gnupg2 wget
	;;
esac

/usr/sbin/td-agent-gem install --no-document serverspec
wget https://packages.confluent.io/deb/6.0/archive.key
gpg2 --homedir /tmp --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/confluent-archive-keyring.gpg --import archive.key
chmod 644 /usr/share/keyrings/confluent-archive-keyring.gpg
echo "deb [arch=${architecture} signed-by=/usr/share/keyrings/confluent-archive-keyring.gpg] https://packages.confluent.io/deb/6.0 stable main" > /etc/apt/sources.list.d/confluent.list
apt update && apt install -y confluent-community-2.13 ${java_jdk} netcat-openbsd

export KAFKA_OPTS=-Dzookeeper.4lw.commands.whitelist=ruok
/usr/bin/zookeeper-server-start /etc/kafka/zookeeper.properties  &
N_POLLING=30
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
export PATH=/opt/td-agent/bin:$PATH
export INSTALLATION_TEST=true
cd /fluentd && rake serverspec:linux
