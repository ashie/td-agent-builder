# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

ARG FROM=ubuntu:bionic
FROM ${FROM}

COPY qemu-* /usr/bin/

RUN \
  echo "debconf debconf/frontend select Noninteractive" | \
    debconf-set-selections

ARG DEBUG

RUN sed -i'' -e 's/^# deb-src/deb-src/g' /etc/apt/sources.list

RUN \
  quiet=$([ "${DEBUG}" = "yes" ] || echo "-qq") && \
  apt update ${quiet} && \
  apt install -y -V ${quiet} \
    build-essential \
    debhelper \
    devscripts \
    ruby-dev \
    ruby-bundler \
    libedit2 \
    libncurses5-dev \
    libyaml-dev \
    git \
    pkg-config \
    libssl-dev \
    libpq-dev \
    tar \
    lsb-release \
    zlib1g-dev && \
  apt build-dep -y ruby && \
  apt clean && \
  # raise IPv4 priority
  sed -i'' -e 's,#precedence ::ffff:0:0/96  100,precedence ::ffff:0:0/96  100,' /etc/gai.conf && \
  # enable multiplatform feature
  gem install --no-document bundler && \
  rm -rf /var/lib/apt/lists/*
