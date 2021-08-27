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

ARG FROM=opensuse/leap:42.3
FROM ${FROM}

COPY qemu-* /usr/bin/

ARG DEBUG

RUN \
  quiet=$([ "${DEBUG}" = "yes" ] || echo "--quiet") && \
  zypper ${quiet} refresh && \
  zypper ${quiet} install -y patterns-openSUSE-devel_C_C++ && \
  zypper ${quiet} install -y \
    ruby-devel  \
    ruby2.4 \
    ruby2.4-rubygem-rake \
    ruby2.4-rubygem-bundler \
    libedit-devel \
    ncurses-devel \
    libyaml-devel \
    git \
    cyrus-sasl-devel \
    pkg-config \
    gcc-c++ \
    rpm-build \
    rpmdevtools \
    libopenssl-devel \
    tar \
    zlib-devel \
    rpmlint && \
    # raise IPv4 priority
    echo "precedence ::ffff:0:0/96 100" > /etc/gai.conf && \
  zypper ${quiet} clean --all
