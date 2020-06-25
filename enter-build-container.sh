#!/bin/bash


if [ "$1" = "" ] ; then
		echo "Usage: $0 workspace-directory"
		echo "   ex: $0 ~/imx-yocto-bsp"
		exit 1
fi

WORKSPACEDIR=$1

if [ ! -d $WORKSPACEDIR ] ; then
	echo "Creating $WORKSPACEDIR..."
	mkdir -p $WORKSPACEDIR
fi

# note: the custom seccomp profile is used to enable strace for debugging build issues
docker run -v $WORKSPACEDIR:/var/yocto -it --security-opt "seccomp:./custom-seccomp-profile.json" centos7-imx-yocto:zeus-latest bash
