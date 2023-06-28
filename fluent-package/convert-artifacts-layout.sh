#!/bin/bash

# Utility script to convert repository layout for packages.treasuredata.com
#
# Usage:
#   $ convert-artifacts-layout.sh apt
#   $ convert-artifacts-layout.sh yum

set -ex

TD_AGENT_DIR=$(dirname $(realpath $0))
REPOSITORY_TYPE=""
ARTIFACTS_DIR="artifacts"
case $1 in
    apt|deb)
	REPOSITORY_TYPE=apt
	REPOSITORY_PATH=$TD_AGENT_DIR/$REPOSITORY_TYPE/repositories
	for d in bullseye bookworm focal jammy; do
	    case $d in
		bullseye|bookworm)
		    # e.g. mapping debian/pool/buster/main/t/td-agent/ => 5/debian/buster/pool/contrib/t/td-agent
		    #      mapping debian/pool/buster/main/f/fluent-package/ => 5/debian/buster/pool/contrib/f/fluent-package
		    mkdir -p $ARTIFACTS_DIR/5/debian/$d/pool/contrib/t/td-agent
		    mkdir -p $ARTIFACTS_DIR/5/debian/$d/pool/contrib/f/fluent-package
		    find $REPOSITORY_PATH/debian/pool/$d -name 'td-agent*.deb' -not -name '*dbgsym*' -exec cp {} $ARTIFACTS_DIR/5/debian/$d/pool/contrib/t/td-agent \;
		    find $REPOSITORY_PATH/debian/pool/$d -name 'fluent-package*.deb' -not -name '*dbgsym*' -exec cp {} $ARTIFACTS_DIR/5/debian/$d/pool/contrib/f/fluent-package \;
		    ;;
		focal|jammy)
		    # e.g. mapping ubuntu/pool/.../main/t/td-agent/ => 5/ubuntu/.../pool/contrib/t/td-agent
		    #      mapping ubuntu/pool/.../main/f/fluent-package/ => 5/ubuntu/.../pool/contrib/f/fluent-package
		    mkdir -p $ARTIFACTS_DIR/5/ubuntu/$d/pool/contrib/t/td-agent
		    mkdir -p $ARTIFACTS_DIR/5/ubuntu/$d/pool/contrib/f/fluent-package
		    find $REPOSITORY_PATH/ubuntu/pool/$d -name 'td-agent*.deb' -exec cp {} $ARTIFACTS_DIR/5/ubuntu/$d/pool/contrib/t/td-agent \;
		    find $REPOSITORY_PATH/ubuntu/pool/$d -name 'fluent-package*.deb' -exec cp {} $ARTIFACTS_DIR/5/ubuntu/$d/pool/contrib/f/fluent-package \;
		    ;;
		*)
		    exit 1
		    ;;
	    esac
	done
	;;
    yum|rpm)
	REPOSITORY_TYPE=yum
	REPOSITORY_PATH=$TD_AGENT_DIR/$REPOSITORY_TYPE/repositories
	for dist in centos amazon rocky almalinux; do
	    dist_dest=$dist
	    if [ $dist = "centos" -o $dist = "rocky" -o $dist = "almalinux" ]; then
		dist_dest="redhat"
	    fi
	    for release in 2 7 8 9; do
		if [ $dist = "amazon" -a $release -ne 2 ]; then
		    echo "skip $dist:$release"
		    continue
		fi
		if [ $dist = "centos" -a $release -ne 7 ]; then
		    echo "skip $dist:$release"
		    continue
		fi
		if [ $dist = "rocky" -a $release -ne 8 ]; then
		    echo "skip $dist:$release"
		    continue
		fi
		if [ $dist = "almalinux" -a $release -ne 9 ]; then
		    echo "skip $dist:$release"
		    continue
		fi
		for arch in aarch64 x86_64; do
		    # e.g. mapping amazon/2/x86_64/Packages/ => 5/amazon/2/x86_64
		    mkdir -p $ARTIFACTS_DIR/5/$dist_dest/$release/$arch
		    find $REPOSITORY_PATH/$dist/$release/$arch -name '*.rpm' -not -name '*debug*' -exec cp {} $ARTIFACTS_DIR/5/$dist_dest/$release/$arch \;
		done
	    done
	done
	;;
esac

