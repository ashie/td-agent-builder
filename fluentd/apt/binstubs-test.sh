#!/bin/bash

set -exu

apt update
apt install -V -y lsb-release

. $(dirname $0)/commonvar.sh

apt install -V -y \
  ${repositories_dir}/${distribution}/pool/${code_name}/${channel}/*/*/*_${architecture}.deb

echo "BINSTUBS TEST"
/opt/td-agent/bin/ruby /fluentd/td-agent/binstubs-test.rb
if [ $? -eq 0 ]; then
    echo "Checking existence of binstubs: OK"
else
    echo "Checking existence of binstubs: NG"
    exit 1
fi
