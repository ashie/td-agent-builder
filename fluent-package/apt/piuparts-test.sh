#!/bin/bash

set -exu

apt update
apt install -V -y lsb-release

. $(dirname $0)/commonvar.sh

if [ -z "$(apt-cache show piuparts 2>/dev/null)" ]; then
	# No piuparts package for noble and oracular. See https://packages.ubuntu.com/search?suite=noble&searchon=names&keywords=piuparts
	echo "As ${code_name} does not support piuparts, so piuparts test for ${code_name} is disabled"
	exit 0
fi

find ${repositories_dir}
DEBIAN_FRONTEND=noninteractive apt install -V -y piuparts mount gnupg curl eatmydata
gpg_command=gpg
curl https://packages.treasuredata.com/GPG-KEY-td-agent > td-agent.gpg
curl https://packages.treasuredata.com/GPG-KEY-fluent-package > fluent-package.gpg
FLUENT_PACKAGE_KEYRING=/usr/share/keyrings/fluent-package-archive-keyring.gpg
${gpg_command} --no-default-keyring --keyring $FLUENT_PACKAGE_KEYRING --import td-agent.gpg
${gpg_command} --no-default-keyring --keyring $FLUENT_PACKAGE_KEYRING --import fluent-package.gpg
CHROOT=/var/lib/chroot/${code_name}-root
mkdir -p $CHROOT
debootstrap --include=ca-certificates ${code_name} $CHROOT ${mirror}
cp $FLUENT_PACKAGE_KEYRING $CHROOT/usr/share/keyrings/
chmod 644 $CHROOT/usr/share/keyrings/fluent-package-archive-keyring.gpg
chroot $CHROOT apt install -V -y libyaml-0-2
package=${repositories_dir}/${distribution}/pool/${code_name}/${channel}/*/*/*_${architecture}.deb
cp ${package} /tmp
echo "deb [signed-by=/usr/share/keyrings/fluent-package-archive-keyring.gpg] https://packages.treasuredata.com/lts/5/${distribution}/${code_name}/ ${code_name} contrib" | tee $CHROOT/etc/apt/sources.list.d/fluent-package.list
rm -rf $CHROOT/opt
piuparts --distribution=${code_name} \
	 --existing-chroot=${CHROOT} \
	 --skip-logrotatefiles-test \
	 /tmp/*_${architecture}.deb
