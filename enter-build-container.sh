#!/bin/bash

if [ "$1" = "" ] ; then
	echo "Usage: $0 shared-data-directory [workspace-name]"
	echo "   ex: $0 ~/imx-yocto-bsp"
	echo "   ex: $0 ~/imx-yocto-bsp my-other-workspace"
	exit 1
fi

if [ "$2" != "" ] ; then
	IMX_OS_WORKSPACE=$2
fi

WORKSPACEDIR=$1

if [ ! -d $WORKSPACEDIR ] ; then
	echo "Creating $WORKSPACEDIR..."
	mkdir -p $WORKSPACEDIR
fi

# note: the custom seccomp profile is used to enable strace for debugging build issues
docker run -v $WORKSPACEDIR:/var/yocto -it --security-opt "seccomp:./custom-seccomp-profile.json" -e IMX_OS_WORKSPACE=$IMX_OS_WORKSPACE centos7-imx-yocto:warrior-latest bash
