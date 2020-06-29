# Instructions

## Clone this repo

Go to the directory where you want to keep code and clone this repo:

```
cd $MY_CODE_DIRECTORY
git clone https://github.com/xtianbetz/imx-bsp-bootstrap.git
cd imx-bsp-bootstrap
```

## Build the docker container

A Docker container is used to make reproducing the build environment as easy as
possible. The first step is therefore to run 'docker build' and create
a fully-equipped build container. Look closer at the 'Dockerfile' in this repo
if you want to know more about setting up a build host.

Build the container with the following command:

```
docker build -t centos7-imx-yocto:zeus-latest .
```

## Enter the build container

Enter the build container using the following helper script. The first argument
is a local "workspace" directory that you want to use for build files and
artifacts. The directory will be made for you if required. Remember that this
location must have at least 100GB of disk space free.

```
./enter-build-container.sh $MY_WORKSPACE_DIRECTORY
```

For example, if you have a large disk mounted as /data, you may have
a workspace directory there and use it like so:

```
./enter-build-container.sh /data/yocto/imx-yocto-bsp
```

## Building an Official BSP release

Enter the docker container and execute the following commands:

Change directory to /var/yocto (which is actually also $MY_WORKSPACE_DIRECTORY
on the container host):
```
cd /var/yocto
```

Make a directory for the release you are building:

```
mkdir imx-5.4.3-2.0.0
cd imx-5.4.3-2.0.0/
```

Initialize the repo by downloading the appropriate pinned BSP release XML.

```
repo init -u https://source.codeaurora.org/external/imx/imx-manifest -b imx-linux-zeus -m imx-5.4.3-2.0.0.xml
```

Download all layers and recipes:

```
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

NOTE: This process will take at least a half hour on a very fast multi-core
machine and will use close to 100GB of disk space.

## Workarounds you may need

The 5.4.24-2.1.0 release seems to have an issue building the 'nxp-wlan-sdk'
package. You may need to disable the machine feature that brings in this
package by adding the following to 'conf/local.conf' (in the bld-wayland
directory). The 5.4.3-2.0.0 release seems to build fine without this workaround.

```
MACHINE_FEATURES_remove = "nxp8987 "
```

## Writing an image to eMMC using uuu

### General Process of using UUU

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

#### Example of using UUU

You can use 'uuu' easily by placing the files from the Yocto deploy directory
into a directory along with the uuu.auto script file from this repo.

```
cd $MY_WORKSPACE_DIRECTORY
mkdir imx-5.4.3-2.0.0-imx6qpsabresd
cd imx-5.4.3-2.0.0-imx6qpsabresd
```

If you're running the build container on a VM or another machine, you should
copy the files you want to write to eMMC now. Otherwise you can just copy the
files directly from $MY_WORKSPACE_DIRECTORY.

```
scp $MY_BUILD_MACHINE_HOSTNAME:/data/yocto/imx-yocto-bsp/imx-5.4.3-2.0.0/bld-wayland/tmp/deploy/images/imx6qpsabresd/u-boot-sd-optee-2019.04-r0.imx .
scp $MY_BUILD_MACHINE_HOSTNAME:/data/yocto/imx-yocto-bsp/imx-5.4.3-2.0.0/bld-wayland/tmp/deploy/images/imx6qpsabresd/imx-image-core-imx6qpsabresd-20200628215652.rootfs.wic.bz2 .
```

Extract the compressed disk image file:

```
bunzip2 imx-image-core-imx6qpsabresd-20200628215652.rootfs.wic.bz2
```

Copy the template uuu.auto script from this repo:
```
cp $MY_CODE_DIRECTORY/imx-bsp-bootstrap/uuu.auto .
```

Create symlinks so you can use the uuu.auto script without editing it:
```
ln -sf u-boot-sd-optee-2019.04-r0.imx u-boot.bin
ln -sf imx-image-core-imx6qpsabresd-20200628215652.rootfs.wic disk-image.wic
```

Finally, power on the board and run 'uuu' with the directory you created as an
argument. Remember to force serial download mode by setting the DIP switches to
boot from SD card and remove the SD card (for example).

```
cd ..
sudo uuu 5.4.3-2.0.0-imx6qpsabresd
```

If you are monitoring the serial output in a terminal emulator you will be able
to confirm that the download process is running.

After 'uuu' completes, you can power down the board and set the DIP switches to
eMMC boot. You should see u-boot boot, and then Linux.

## Creating a custom board layer

### Creating and enabling a new layer configuration

Create a new bitbake layer to start adding customizations:

```
mkdir -p ../sources/meta-imx6example/conf
```

Use your favorite text editor (vim/nano/emacs/etc) to create and edit
a new layer.conf file:

```
$YOUR_FAVORITE_EDITOR ../sources/meta-imx6example/conf/layer.conf
```

The layer.conf file should have the following contents:

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
layer is being picked up correctly. This time the build should only take
a minute or so. You should see a warning like this:

```
WARNING: No bb files matched BBFILE_PATTERN_imx6example '^/var/yocto/imx-5.4.24-2.1.0/sources/meta-imx6example/'
```

Don't worry about this warning because we're going to add some BB files in the next steps.

### Create a new board config based on the i.MX6QP

We'll start by copying the configuration of the i.MX6QP SABRE board into a new
machine conf. The new MACHINE will be called 'imx6example'. This section will
create a machine which differs from the 'imx6qpsabresd' in name only. It will
produce a nearly identical image as the previous steps, though the machine name
will appear in the console output so you can confirm you are moving in the right
direction. We'll gain confidence building this custom machine and then make
more customizations later for a custom board based on the iMX6DL.

```
mkdir -p ../sources/meta-imx6example/conf/machine
cp ../sources/meta-imx/meta-bsp/conf/machine/imx6qpsabresd.conf ../sources/meta-imx6example/conf/machine/imx6example.conf
```

Edit the imx6example.conf file. Your imx6example.conf should look like this when done:

```
#@TYPE: Machine
#@NAME: NXP i.MX6Q Plus SABRE Smart Device
#@SOC: i.MX6QP
#@DESCRIPTION: Machine configuration for NXP i.MX6QP SABRE Smart Device
#@MAINTAINER: Your Name <your.name@organization.com>

MACHINEOVERRIDES =. "mx6:mx6q:"

include conf/machine/include/imx6sabresd-common.inc

KERNEL_DEVICETREE = "imx6qp-sabresd.dtb imx6qp-sabresd-btwifi.dtb imx6qp-sabresd-hdcp.dtb \
                     imx6qp-sabresd-ldo.dtb"

# imx6example customization #1: Disable optee
#MACHINE_FEATURES_append = " optee"

UBOOT_CONFIG ??= "${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'sd-optee', 'sd', d)}"
UBOOT_CONFIG[sd] = "mx6qpsabresd_config,sdcard"
UBOOT_CONFIG[sata] = "mx6qpsabresd_sata_config"
UBOOT_CONFIG[mfgtool] = "mx6qpsabresd_config"
UBOOT_CONFIG[sd-optee] = "mx6qpsabresd_optee_config,sdcard"

OPTEE_BIN_EXT = "6qpsdb"

# imx6example customization #2: declare our machine compatible with u-boot-imx
COMPATIBLE_MACHINE_u-boot-imx = "(mx6|mx7|mx8|imx6example)"

# imx6example customization #3:Change Override IMAGE_BOOT_FILES to
# workaround build errors (only needed for 5.4.24-2.1.0)
IMAGE_BOOT_FILES = " \
    ${KERNEL_IMAGETYPE} \
    ${KERNEL_DEVICETREE} \
"
```

Check your work on this step by rebuilding imx-image-core, this time overriding
the machine with your custom machine:

```
MACHINE=imx6example bitbake imx-image-core
```

Use 'uuu' to load it on the SABRE Board again. You should see your new machine
printed on the console (i.e. when logging into Linux).

### Create a new board config based on the i.MX6DL

If your custom board is based in the i.MX6DL, you should copy it's
machine.conf. In this case we're making a new MACHINE called 'imx6dlexample'.

```
mkdir -p ../sources/meta-imx6example/conf/machine
cp ../sources/meta-imx/meta-bsp/conf/machine/imx6dlsabresd.conf ../sources/meta-imx6example/conf/machine/imx6dlexample.conf
```

Again, edit the machine configuration file:

```
$YOUR_FAVORITE_EDITOR ../sources/meta-imx6example/conf/machine/imx6dlexample.conf
```

It should look something like this when done:

```
#@TYPE: Machine
#@NAME: NXP i.MX6DL SABRE Smart Device
#@SOC: i.MX6DL
#@DESCRIPTION: Machine configuration for NXP i.MX6DL SABRE Smart Device
#@MAINTAINER: Your Name <your.name@organization.com>

MACHINEOVERRIDES =. "mx6:mx6dl:"

require conf/machine/include/imx6sabresd-common.inc

KERNEL_DEVICETREE = "imx6dl-sabresd.dtb imx6dl-sabresd-ldo.dtb imx6dl-sabresd-hdcp.dtb \
                     imx6dl-sabresd-enetirq.dtb imx6dl-sabresd-btwifi.dtb"

# imx6example customization #1: Disable optee
#MACHINE_FEATURES_append = " optee"

UBOOT_CONFIG ??= "${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'sd-optee', 'sd', d)}"
UBOOT_CONFIG[sd] = "mx6dlsabresd_config,sdcard"
UBOOT_CONFIG[epdc] = "mx6dlsabresd_epdc_config"
UBOOT_CONFIG[mfgtool] = "mx6dlsabresd_config"
UBOOT_CONFIG[sd-optee] = "mx6dlsabresd_optee_config,sdcard"

OPTEE_BIN_EXT = "6dlsdb"

MACHINE_FIRMWARE += "firmware-imx-epdc"

# imx6example customization #2: declare our machine compatible with u-boot-imx
COMPATIBLE_MACHINE_u-boot-imx = "(mx6|mx7|mx8|imx6dlexample)"
```

Check your work on this step by rebuilding imx-image-core, this time overriding
the machine with your custom machine:

```
MACHINE=imx6dlexample bitbake imx-image-core
```

You should get a clean build. However, this time you will not use 'uuu' to load
it on the SABRE Board because that has an i.MX6Q SoC, not an i.MX6DL. Go to the
next section where we will create u-boot patches for a custom i.MX6DL board.

### Adding u-boot customizations

A custom board will almost certainly require a patch for u-boot-imx, with custom
device configuration data (DCD), devicetree configuration, etc. Imagine you have
created this patch with the filename u-boot-imx-imx6dlexample.patch.

First we're going to create some directories within our new layer to organize
our bitbake recipe append file (bbappend) and u-boot patch.

```
mkdir -p ../sources/meta-imx6example/recipes-bsp/u-boot-imx
mkdir -p ../sources/meta-imx6example/recipes-bsp/u-boot-imx/imx6dlexample
```

Next we'll create a new bbappend file. This file will instruct bitbake to apply
a special patch for this machine only.

```
$YOUR_FAVORITE_EDITOR ../sources/meta-imx6example/recipes-bsp/u-boot-imx/u-boot-imx_%.bbappend
```

The bbappend file should look like this:

```
# Add a special patch for the imx6dlexample machine
SRC_URI_append_imx6dlexample = " file://u-boot-imx-imx6dlexample.patch"

# Tell bitbake to search this directory for additional u-boot patches
FILESEXTRAPATHS_prepend := "${THISDIR}:"
```

Now copy your patch into place. For instance you can put the patch temporarily
on the container host machine in $MY_WORKSPACE_DIRECTORY. This way  it is
accessible in the build container (from /var/yocto).

```
cp /var/yocto/u-boot-imx-imx6dlexample.patch ../sources/meta-imx6example/recipes-bsp/u-boot-imx/imx6dlexample/
```

Finally, attempt to build an image for your new patched machine.

```
MACHINE=imx6dlexample bitbake imx-image-core
```

At this point, you can try copying files again and loading the image again with
'uuu'. It will likely or possibly not boot Linux correctly though you can
confirm at least that you have a working u-boot.

### Adding kernel customizations.

TODO: explain how to make bbappend for linux-imx and add patches using
SRC_URI_append.

## Resources

* [Official README](https://source.codeaurora.org/external/imx/imx-manifest/tree/README?h=imx-linux-zeus) that this repo was adapted from.
* [Creating your own Bitbake Layer](https://www.yoctoproject.org/docs/latest/dev-manual/dev-manual.html#creating-your-own-layer)
