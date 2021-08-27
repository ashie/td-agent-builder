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
	for d in buster bullseye xenial bionic focal; do
	    case $d in
		buster|bullseye)
		    # e.g. mapping debian/pool/buster/main/t/td-agent/ => 4/debian/buster/pool/contrib/t/td-agent
		    mkdir -p $ARTIFACTS_DIR/4/debian/$d/pool/contrib/t/td-agent
		    find $REPOSITORY_PATH/debian/pool/$d -name '*.deb' -not -name '*dbgsym*' -exec cp {} $ARTIFACTS_DIR/4/debian/$d/pool/contrib/t/td-agent \;
		    ;;
		xenial|bionic|focal)
		    # e.g. mapping ubuntu/pool/.../main/t/td-agent/ => 4/ubuntu/.../pool/contrib/t/td-agent
		    mkdir -p $ARTIFACTS_DIR/4/ubuntu/$d/pool/contrib/t/td-agent
		    find $REPOSITORY_PATH/ubuntu/pool/$d -name '*.deb' -exec cp {} $ARTIFACTS_DIR/4/ubuntu/$d/pool/contrib/t/td-agent \;
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
	for dist in centos amazon; do
	    dist_dest=$dist
	    if [ $dist = "centos" ]; then
		dist_dest="redhat"
	    fi
	    for release in 2 7 8; do
		if [ $dist = "amazon" -a $release -ne 2 ]; then
		    echo "skip $dist:$release"
		    continue
		fi
		if [ $dist = "centos" -a $release -eq 2 ]; then
		    echo "skip $dist:$release"
		    continue
		fi
		for arch in aarch64 x86_64; do
		    # e.g. mapping amazon/2/x86_64/Packages/ => 4/amazon/2/x86_64
		    mkdir -p $ARTIFACTS_DIR/4/$dist_dest/$release/$arch
		    find $REPOSITORY_PATH/$dist/$release/$arch -name '*.rpm' -not -name '*debug*' -exec cp {} $ARTIFACTS_DIR/4/$dist_dest/$release/$arch \;
		done
	    done
	done
	;;
esac

