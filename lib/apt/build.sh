#!/bin/sh
# -*- sh-indentation: 2; sh-basic-offset: 2 -*-
#
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

LANG=C

set -u

run()
{
  "$@"
  if test $? -ne 0; then
    echo "Failed $@"
    exit 1
  fi
}

. /host/env.sh

distribution=$(lsb_release --id --short | tr 'A-Z' 'a-z')
code_name=$(lsb_release --codename --short)
case "${distribution}" in
  debian)
    component=main
    ;;
  ubuntu)
    component=universe
    ;;
esac
architecture=$(dpkg-architecture -q DEB_BUILD_ARCH)

run mkdir -p build
run cp /host/tmp/${PACKAGE}-${VERSION}.tar.gz \
  build/${PACKAGE}_${VERSION}.orig.tar.gz
run cd build
run tar xfz ${PACKAGE}_${VERSION}.orig.tar.gz
case "${VERSION}" in
  *~dev*)
    run mv ${PACKAGE}-$(echo $VERSION | sed -e 's/~dev/-dev/') \
        ${PACKAGE}-${VERSION}
    ;;
esac
run cd ${PACKAGE}-${VERSION}/
platform="${distribution}-${code_name}"
if [ -d "${PACKAGEDIR}/${platform}-${architecture}" ]; then
  run cp -rp "${PACKAGEDIR}/${platform}-${architecture}" debian
elif [ -d "${PACKAGEDIR}/debian.${platform}" ]; then
  run cp -rp "${PACKAGEDIR}/debian.${platform}" debian
elif [ -d "${PACKAGEDIR}/debian" ]; then
  run cp -rp "${PACKAGEDIR}/debian" debian
fi

# setup lintian profile
run mkdir -p ~/.lintian/profiles/${PACKAGE}/
run cp "debian/lintian/${PACKAGE}/${distribution}.profile" ~/.lintian/profiles/${PACKAGE}/${distribution}.profile
# export DEB_BUILD_OPTIONS=noopt
DISTRIBUTION=`lsb_release -c | cut -f2`
sed -i'' -E "s/^($PACKAGE \(\S+\)) unstable;/\1 $DISTRIBUTION;/g" debian/changelog
cat .bundle/config
if [ "${DEBUG:-no}" = "yes" ]; then
  if [ "${LINTIAN:-yes}" = "yes" ]; then
    run debuild -us -uc --lintian-opts --profile ${PACKAGE}/${distribution}
  else
    run debuild --no-lintian -us -uc --source-option=--auto-commit
  fi
else
  if [ "${LINTIAN:-yes}" = "yes" ]; then
    run debuild -us -uc --lintian-opts --profile ${PACKAGE}/${distribution} > /dev/null
  else
    run debuild --no-lintian -us -uc > /dev/null
  fi
fi
run cd -

repositories="/host/repositories"
package_initial=$(echo "${PACKAGE}" | sed -e 's/\(.\).*/\1/')
pool_dir="${repositories}/${distribution}/pool/${code_name}/${component}/${package_initial}/${PACKAGE}"
run mkdir -p "${pool_dir}/"
run cp *.tar.* *.dsc *.deb "${pool_dir}/"
# Ubuntu bionic and focal rename dbgsym package extension to ddeb.
if [ -f *.ddeb ]; then
  run cp *.ddeb "${pool_dir}/"
fi

run chown -R "$(stat --format "%u:%g" "${repositories}")" "${repositories}"
