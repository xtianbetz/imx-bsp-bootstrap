# Instructions

## Build the docker container

```
docker build -t centos7-imx-yocto:zeus-latest .
```

## Enter the docker container

Enter the build container using the following command. The first argument is
a local directory on your machine you want to use for build files and
artifacts. The directory will be made for you if required.

```
./enter-build-container.sh /data/yocto/imx-yocto-bsp
```

## Building an Official BSP release

Enter the docker container and execute the following commands:

```
cd /var/yocto
mkdir 5.4.3-2.0.0
cd 5.4.3-2.0.0
repo init -u https://source.codeaurora.org/external/imx/imx-manifest -b imx-linux-zeus -m imx-5.4.3-2.0.0.xml
repo sync
```

Setup the build for the i.MX6 QuadPlus Sabre Board:

```
MACHINE=imx6qpsabresd DISTRO=fsl-imx-fb source ./imx-setup-release.sh -b bld-fb
```

Note: You should use a different MACHINE such as imx6dlsabresd if needed. For
a list of additional machines, see the [i.MX Yocto Project User's
Guide](https://www.nxp.com/docs/en/user-guide/IMX_YOCTO_PROJECT_USERS_GUIDE.pdf)

Accept the EULA.

Finally you can build the image as follows:

```
bitbake imx-image-core
```

## Resources

* [Official README](https://source.codeaurora.org/external/imx/imx-manifest/tree/README?h=imx-linux-zeus) that this repo was adapted from.
