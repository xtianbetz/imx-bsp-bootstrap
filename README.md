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
Board](https://www.nxp.com/design/development-boards/i-mx-evaluation-and-development-boards/sabre-board-for-smart-devices-based-on-the-i-mx-6quadplus-applications-processors:RD-IMX6QP-SABRE) using the imx6qpsabresd machine, and the fsl-imx-wayland distro.

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

NOTE: This process will take at least a half hour on a very fast multicore
machine and will use close to 100GB of disk space.

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

## Creating a custom board layer

### Creating and enabling a new layer configuration

Create a new bitbake layer to start adding customizations:

```
mkdir -p ../sources/meta-imx6example/conf
```

Use your favorite text editor (vim/nano/emacs/etc) to create and edit the
a new layer.conf file:

```
$YOUR_FAVORITE_EDITOR ../sources/meta-imx6example/conf/layer.conf
```

The layer.conf file should have contents that looks like this:

```
# We have a conf and classes directory, add to BBPATH
BBPATH .= ":${LAYERDIR}"

# We have recipes-* directories, add to BBFILES
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
${LAYERDIR}/recipes-*/*/*.bbappend"

BBFILE_COLLECTIONS += "imx6example"
BBFILE_PATTERN_imx6example = "^${LAYERDIR}/"
BBFILE_PRIORITY_imx6example = "5"
LAYERVERSION_imx6example = "4"
LAYERSERIES_COMPAT_imx6example = "zeus"
```

Finally, edit conf/bblayers.conf and add your layer on the last line:

```
BBLAYERS += "${BSPDIR}/sources/meta-imx6example"
```

Perform another 'bitbake imx-image-core' to confirm your
your layer is being picked up correctly. You will see a warning like this:

```
WARNING: No bb files matched BBFILE_PATTERN_imx6example '^/var/yocto/imx-5.4.24-2.1.0/sources/meta-imx6example/'
```

Don't worry about this warning because we're going to add some BB files in the next steps.

### Create a new board config

We'll start by copying the configuration of the i.MX6QP SABRE board into a new
machine conf. The new MACHINE will be called 'imx6example'.

```
mkdir ../sources/meta-imx6example/conf/machine
cp ../sources/meta-imx/meta-bsp/conf/machine/imx6qpsabresd.conf ../sources/meta-imx6example/conf/machine/imx6example.conf
```

Edit the imx6example.conf and comment out all lines with 'optee' or 'OPTEE'
(OPTEE is a secure-enclave OS used for secure computations and secret storage;
disabling it will help us ignore some build errors associated with the custom
board). We also make some other changes for making this machine compatible with
u-boot-imx and setting IMAGE_BOOT_FILES.

Your imx6example.conf should look like this when done:

```
@TYPE: Machine
#@NAME: NXP i.MX6Q Plus SABRE Smart Device
#@SOC: i.MX6QP
#@DESCRIPTION: Machine configuration for NXP i.MX6QP SABRE Smart Device
#@MAINTAINER: Lauren Post <lauren.post@nxp.com>

MACHINEOVERRIDES =. "mx6:mx6q:"

include conf/machine/include/imx6sabresd-common.inc

KERNEL_DEVICETREE = "imx6qp-sabresd.dtb imx6qp-sabresd-btwifi.dtb imx6qp-sabresd-hdcp.dtb \
                     imx6qp-sabresd-ldo.dtb"

#MACHINE_FEATURES_append = " optee"

#UBOOT_CONFIG ??= "${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'sd-optee', 'sd', d)}"
# Add this line to set a default u-boot configuration
UBOOT_CONFIG ??= "sd"
UBOOT_CONFIG[sd] = "mx6qpsabresd_config,sdcard"
UBOOT_CONFIG[sata] = "mx6qpsabresd_sata_config"
UBOOT_CONFIG[mfgtool] = "mx6qpsabresd_config"
#UBOOT_CONFIG[sd-optee] = "mx6qpsabresd_optee_config,sdcard"

#OPTEE_BIN_EXT = "6qpsdb"

# Add compatible machine so we can use u-boot-imx
COMPATIBLE_MACHINE_u-boot-imx = "(mx6|mx7|mx8|imx6example)"

# Override IMAGE_BOOT_FILES to workaround build errors
IMAGE_BOOT_FILES = " \
    ${KERNEL_IMAGETYPE} \
    ${KERNEL_DEVICETREE} \
"
```

Check your work on this step by rebuilding imx-image-core, this time overriding
the machine with your custom machine:

```
MACHINE=imx6example bitbake -e imx-image-core
```

Use 'uuu' to load it on the SABRE Board again.

### Adding u-boot customizations

TODO: explain how to make bbappend for u-boot-imx and add patches using
SRC_URI_append.

### Adding kernel customizations.

TODO: explain how to make bbappend for linux-imx and add patches using
SRC_URI_append.

## Resources

* [Official README](https://source.codeaurora.org/external/imx/imx-manifest/tree/README?h=imx-linux-zeus) that this repo was adapted from.
* [Creating your own Bitbake Layer](https://www.yoctoproject.org/docs/latest/dev-manual/dev-manual.html#creating-your-own-layer)
