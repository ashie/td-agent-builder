#!/bin/bash

# Utility to manage rpm/deb repositories for packages.treasuredata.com
#
# Usage:
#   $ manage-fluent-repositories.sh COMMAND FLUENT_RELEASE_DIR
#
# NOTE: setup AccessKeyId, SecretAccessKey, SessionToken and AWS release-td-agent profile in beforehand
#   $ aws sts get-session-token --serial-number arn:aws:iam::523683666290:mfa/clearcode-xxx --profile USER_PROFILE --duration-seconds 129600 --token-code XXXXX
#

set -e

function usage {
    cat <<EOF
Usage:
  $0 COMMAND FLUENT_RELEASE_PROFILE FLUENT_RELEASE_DIR FLUENT_PACKAGE_VERSION"

Example:
  $ $0 ls release-td-agent
  $ $0 download release-td-agent /tmp/td-agent-release
  $ $0 deb release-td-agent /tmp/td-agent-release 4.2.0
  $ $0 rpm release-td-agent /tmp/td-agent-release 4.2.0
  $ $0 upload release-td-agent /tmp/td-agent-release
EOF
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

COMMAND=$1
FLUENT_RELEASE_PROFILE=$2
FLUENT_RELEASE_DIR=$3
FLUENT_PACKAGE_VERSION=$4
SIGNING_KEY=BEE682289B2217F45AF4CC3F901F9177AB97ACBE

if [ -z "$FLUENT_RELEASE_PROFILE" ]; then
    echo "ERROR: No s3 profile for releasing fluentd packages"
    usage
    exit 1
fi

case $COMMAND in
    deb|rpm)
	if [ -z "$FLUENT_PACKAGE_VERSION" ]; then
	    echo "ERROR: No package version for releasing fluentd packages, (e.g export FLUENT_PACKAGE_VERSION=4.2.0)"
	    exit 1
	fi
	;;
esac

case $COMMAND in
    ls)
	# check whether profile and permission is valid
	command="aws s3 ls s3://packages.treasuredata.com --profile $FLUENT_RELEASE_PROFILE"
	echo $command
	$command
	;;
    upload)
	TARGETS="amazon redhat windows macosx debian/buster debian/bullseye ubuntu/focal ubuntu/xenial ubuntu/bionic"
	for target in $TARGETS; do
	    command="aws s3 sync --delete $FLUENT_RELEASE_DIR/4/$target s3://packages.treasuredata.com/4/$target --profile $FLUENT_RELEASE_PROFILE"
	    echo $command
	    $command
	done
	;;
    download)
	VERSIONS="4"
	for target in $VERSIONS; do
	    command="aws s3 sync --delete s3://packages.treasuredata.com/$target $FLUENT_RELEASE_DIR/$target --profile $FLUENT_RELEASE_PROFILE"
	    echo $command
	    $command
	done
	;;
    deb)
	# Use custom .aptly and .aptly.conf (Do not override ~/.aptly)
	rootdir=$(realpath $FLUENT_RELEASE_DIR/../.aptly)
	conf=$(realpath $FLUENT_RELEASE_DIR/../.aptly.conf)
	rm -fr $rootdir
	mkdir -p $rootdir
	cat << EOF > $conf
{
    "rootDir": "$rootdir"
}
EOF
	echo "Ready to type signing passphrase? (process starts in 10 seconds, Ctrl+C to abort)"
	sleep 10
	export GPG_TTY=$(tty)
	for d in buster bullseye xenial bionic focal; do
	    aptly -config=$conf repo create -distribution=$d -component=contrib td-agent4-$d
	    case $d in
		buster|bullseye)
		    aptly -config=$conf repo add td-agent4-$d $FLUENT_RELEASE_DIR/4/debian/$d/
		    aptly -config=$conf snapshot create td-agent4-$d-${FLUENT_PACKAGE_VERSION}-1 from repo td-agent4-$d
		    aptly -config=$conf publish snapshot -component=contrib -gpg-key=$SIGNING_KEY td-agent4-$d-${FLUENT_PACKAGE_VERSION}-1 debian/$d
		    ;;
		xenial|bionic|focal)
		    aptly -config=$conf repo add td-agent4-$d $FLUENT_RELEASE_DIR/4/ubuntu/$d/
		    aptly -config=$conf snapshot create td-agent4-$d-${FLUENT_PACKAGE_VERSION}-1 from repo td-agent4-$d
		    aptly -config=$conf publish snapshot -component=contrib -gpg-key=$SIGNING_KEY td-agent4-$d-${FLUENT_PACKAGE_VERSION}-1 ubuntu/$d
		    ;;
	    esac
	done
	echo
	echo "Don't forget to sync from $rootdir/.public/ to $FLUENT_RELEASE_DIR/4/"
	echo
	;;
    rpm)
	# resign rpm packages
	find $FLUENT_RELEASE_DIR/4 -name "*$FLUENT_PACKAGE_VERSION*.rpm"
	echo "Ready to type signing passphrase? (process starts in 10 seconds, Ctrl+C to abort)"
	sleep 10
	export GPG_TTY=$(tty)
	find $FLUENT_RELEASE_DIR/4 -name "*$FLUENT_PACKAGE_VERSION*.rpm" | xargs rpm --resign --define "_gpg_name support@treasure-data.com"
	find $FLUENT_RELEASE_DIR/4 -name "*$FLUENT_PACKAGE_VERSION*.rpm" | xargs rpm -K

	# sign rpm repository
	find $FLUENT_RELEASE_DIR/4 -name 'repomd.xml'
	for f in `find $FLUENT_RELEASE_DIR/4 -name 'repomd.xml'`; do
	    if [ -f "$f.asc" ]; then
		rm -f $f.asc
	    fi
	    gpg --detach-sign --armor --local-user $SIGNING_KEY $f
	done
	;;
    *)
	usage
	exit 1
	;;
esac
