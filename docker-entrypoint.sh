#!/bin/bash

# Need to source .bashrc to get "repo" into $PATH
. $HOME/.bashrc

IMX_IMG_TYPE="wayland"

if [ -z "$IMX_OS_WORKSPACE" ] ; then
	OS_WORKSPACE=imx-os-workspace
else
	OS_WORKSPACE="$IMX_OS_WORKSPACE"
fi

cd /var/yocto

if [ ! -d "$OS_WORKSPACE" ] ; then
	mkdir $OS_WORKSPACE
fi

cd $OS_WORKSPACE

CWD=$(pwd)

if [ ! -d ".repo" ] ; then
	echo "Initializing repo in $CWD"
	echo "PATH IS $PATH"
	repo init -u https://source.codeaurora.org/external/imx/imx-manifest -b imx-linux-zeus -m imx-5.4.3-2.0.0.xml
	repo sync

	export MACHINE=imx6qpsabresd
	export DISTRO=fsl-imx-wayland
	. ./imx-setup-release.sh -b bld-${IMX_IMG_TYPE}
else
	echo "Using existing environment in $CWD"
	. setup-environment bld-${IMX_IMG_TYPE}
fi

exec "$@"
