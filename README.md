# Instructions

## Build the docker container

```
docker build -t centos7-imx-yocto:zeus-latest .
```

## Enter the docker container

```
/enter-buildbox-container.sh /data/yocto/imx-yocto-bs
```

Note: the directory will be made for you if required.

## Building an Official BSP release

Enter the docker container and execute the following commands:

```
cd /var/yocto
mkdir 5.4.3-2.0.0
cd 5.4.3-2.0.0
repo init -u https://source.codeaurora.org/external/imx/imx-manifest -b imx-linux-zeus -m imx-5.4.3-2.0.0.xml
repo sync
```

Build for the i.MX6 QuadPlus Sabre Board
```
MACHINE=imx6qpsabresd DISTRO=fsl-imx-fb source ./imx-setup-release.sh -b bld-fb
```

Note: You should use a different MACHINE such as imx6dlsabred if needed. For a list
of additional machines, look the i.MX Yocto Project User's Guide PDF, which can
be found in the latest Linux BSP downloads from NXP.

Accept the EULA. Finally you can build the image as follows:

```
bitbake imx-image-core
```

## Resources

* [Official README](https://source.codeaurora.org/external/imx/imx-manifest/tree/README?h=imx-linux-zeus) that this repo was adapted from.
