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
mkdir imx-5.4.24-2.1.0
cd imx-5.4.24-2.1.0
repo init -u https://source.codeaurora.org/external/imx/imx-manifest -b imx-linux-zeus -m imx-5.4.24-2.1.0.xml
repo sync
```

Setup the build for the [i.MX 6QP SABRE
Board](https://www.nxp.com/design/development-boards/i-mx-evaluation-and-development-boards/sabre-board-for-smart-devices-based-on-the-i-mx-6quadplus-applications-processors:RD-IMX6QP-SABRE) using the imx6qpsabresd machine, and the fsl-imx-fb distro.

```
MACHINE=imx6qpsabresd DISTRO=fsl-imx-wayland source ./imx-setup-release.sh -b bld-wayland
```

Note: You should use a different MACHINE such as imx6dlsabresd if needed. For
a list of additional machines, see the [i.MX Yocto Project User's
Guide](https://www.nxp.com/docs/en/user-guide/IMX_YOCTO_PROJECT_USERS_GUIDE.pdf)

Accept the EULA.

Finally you can build the image as follows:

```
bitbake imx-image-core
```

## Fixes or Hacks you may need

The 5.4.24-2.1.0 release seems to have an issue building the 'nxp-wlan-sdk'
package. You may need to disable the machine feature that brings in this
package by adding the following to 'conf/local.conf' (in the bld-wayland
directory)

```
MACHINE_FEATURES_remove = "nxp8987 "
```

## Writing an image to eMMC using uuu

* install a prebuilt uuu or build/install uuu on your machine
* make a new directory on your machine (i.e. $HOME/imx-uuu-workspace)
* grab the u-boot.imx and rootfs.wic.bz2 files from the tmp/deploy/images/$MACHINE directory
* copy 'uuu.auto' from this repo to $YOUR_WORKSPACE_DIRECTORY
* edit uuu.auto and change the filenames, or create symlinks to the files you
  downloaded so you don't have to edit uuu.auto in multiple places.
* power up board in programming mode using dip switches
* run 'uuu $YOUR_WORKSPACE_DIRECTORY' to program the eMMC. The commands in the uuu.auto
  file will be executed (if applicable).
* When uuu is done, remove power to the board and set dip switches to eMMC.
* Power on board. You can check the build date on the u-boot serial console
  output to confirm you have built the right stuff!

TODO: more detailed instructions with examples, links, tips on building uuu.

## Resources

* [Official README](https://source.codeaurora.org/external/imx/imx-manifest/tree/README?h=imx-linux-zeus) that this repo was adapted from.
