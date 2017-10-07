# Copyright (C) 2017 Mirza Krak

# Rockchip BSP default settings

PREFERRED_VERSION_libdrm = "rk"
PREFERRED_VERSION_xserver-xorg = "rk"

XSERVER_DRIVER = "xf86-video-modesetting"
XSERVER_DRIVER_rk3066 = "xf86-video-fbturbo"
XSERVER_DRIVER_rk3188 = "xf86-video-fbturbo"

XSERVER ?= "\
	xserver-xorg \
	xf86-input-libinput \
	${XSERVER_DRIVER} \
"

PREFERRED_PROVIDER_virtual/egl = "rockchip-mali"
PREFERRED_PROVIDER_virtual/libgles1 = "rockchip-mali"
PREFERRED_PROVIDER_virtual/libgles2 = "rockchip-mali"
PREFERRED_PROVIDER_virtual/libopencl = "rockchip-mali"

# Workaround: libmali.so provided by rk having no SONAME field in it
# so add it to fix rdepends problems
ASSUME_SHLIBS += "libEGL.so:rockchip-mali"
ASSUME_SHLIBS += "libGLESv1_CM.so:rockchip-mali"
ASSUME_SHLIBS += "libGLESv2.so:rockchip-mali"
ASSUME_SHLIBS += "libOpenCL.so:rockchip-mali"
ASSUME_SHLIBS += "libgbm.so:rockchip-mali"
ASSUME_SHLIBS += "libwayland-egl.so:rockchip-mali"

# Tune features
#
# TODO: add features for rk3066, rk3188, rv1108
DEFAULTTUNE_rk3036 ?= "cortexa7hf-neon-vfpv4"
DEFAULTTUNE_rk3288 ?= "cortexa17hf-neon-vfpv4"
DEFAULTTUNE_rk3328 ?= "aarch64"
DEFAULTTUNE_rk3399 ?= "aarch64"

# Default kernel and versions
PREFERRED_PROVIDER_virtual/kernel ??= "linux-rockchip"
PREFERRED_VERSION_linux-rockchip ??= "4.4"
PREFERRED_VERSION_linux-rockchip_rv1109 ??= "3.10"

# Serial console setup
SERIAL_CONSOLES = "115200;ttyS2"
SERIAL_CONSOLES_rv1108 = "1500000;ttyS2"
SERIAL_CONSOLES_rk3066 = "115200;ttyFIQ0"
SERIAL_CONSOLES_rk3188 = "115200;ttyFIQ0"
SERIAL_CONSOLES_rk3328 = "1500000;ttyFIQ0"
SERIAL_CONSOLES_rk3399 = "1500000;ttyFIQ0"

# Kernel image type
RK_KERNEL_IMAGETYPE = "zImage"
RK_KERNEL_IMAGETYPE_rk3328 = "Image"
RK_KERNEL_IMAGETYPE_rk3399 = "Image"

KERNEL_IMAGETYPE ??= "${RK_KERNEL_IMAGE}"

RK_KBUILD_DEFCONFIG = "rockchip_linux_defconfig"
RK_KBUILD_DEFCONFIG_rk3066 = "multi_v7_defconfig"
RK_KBUILD_DEFCONFIG_rk3188 = "multi_v7_defconfig"

KBUILD_DEFCONFIG ??= "${RK_KBUILD_DEFCONFIG}"

PREFERRED_PROVIDER_virtual/bootloader ??= "u-boot-rockchip"

RK_SPL_BINARY = "u-boot-spl-dtb.bin"
RK_SPL_BINARY_rk3036 = "u-boot-spl-nodtb.bin"

SPL_BINARY ??= "${RK_SPL_BINARY}"


IMAGE_FSTYPES ??= "ext4 rockchip-gpt-img"
IMAGE_CLASSES += "rockchip-gpt-img rockchip-update-img"
