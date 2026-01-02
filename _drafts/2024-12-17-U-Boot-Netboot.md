By inspecting `IMAGE_BOOT_FILES`, we see that the `meta-raspberrypi` layer
installs `u-boot.bin` into the boot partition as the file `kernel8.img`.

The U-boot configuration tells us how the environment is set up. With grep and
with a little help from `menuconfig`, we can see that the environment is stored
as a file called `uboot.env` in the boot partition:

```
[meta-edtwardy]$ grep '^CONFIG_ENV' build/tmp-glibc/work/stereo_gadget-oe-linux/u-boot/2024.01/build/.config
CONFIG_ENV_IS_IN_FAT=y
CONFIG_ENV_FAT_INTERFACE="mmc"
CONFIG_ENV_FAT_DEVICE_AND_PART="0:1"
CONFIG_ENV_FAT_FILE="uboot.env"
```

Nothing creates that file during the build process. It's intended to be the
location where U-boot stores the environment and reads it back on subsequent
boots. The standard tooling also can't be used to generate a compatible
environment file, either. The file signature does not match one generated using
`mkenvimage`, for example.

It looks like we don't have the option to pre-populate an environment on this
platform. Let's turn to looking at the [build process that creates the default
environment][1], which is built into U-boot and used when `uboot.env` isn't
present. `menuconfig` tells us that the build system knows this board as the
`rpi`, by the value of `CONFIG_SYS_BOARD`, so the first file to look at is
`include/configs/rpi.h`. If the board were using the old-style C environment,
this file would contain a definition for `CFG_EXTRA_ENV_SETTINGS` that would
contain the non-standard environment variables. In U-boot 2024.01, that's not
here.

The next place to look is the environment text file. This will be a text file
with C-preprocessor directives that defines environment variables in
`key=value` fashion. For us, `CONFIG_ENV_SOURCE_FILE` is empty, which means
we're looking for the file `board/raspberrypi/rpi/rpi.env`. Sure enough, at the
bottom of this file, they call out the boot targets:

```
boot_targets=mmc usb pxe dhcp
```

This is great! We can create our own environment text file that's specified in
`CONFIG_ENV_SOURCE_FILE`, which includes this one and overwrites the variables
we care about. Unfortunately, that means patching U-boot.

By default, U-boot ignores serverip if it receives a server IP. We can change this with CONFIG_BOOTP_PREFER_SERVERIP.

[1]: https://docs.u-boot.org/en/latest/usage/environment.html
