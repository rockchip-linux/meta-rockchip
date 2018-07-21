# Copyright (C) 2017 Fuzhou Rockchip Electronics Co., Ltd
# Released under the MIT license (see COPYING.MIT for the terms)

PACKAGECONFIG_GL = "${@bb.utils.contains('DISTRO_FEATURES', 'opengl', 'gles2', '', d)}"
PACKAGECONFIG_FONTS	= "fontconfig"

PACKAGECONFIG_APPEND = " \
	${@bb.utils.contains("DISTRO_FEATURES", "wayland", "xkbcommon-evdev", \
	   bb.utils.contains("DISTRO_FEATURES", "x11", " ", "libinput eglfs gbm", d), d)} \
"
PACKAGECONFIG_append = " ${PACKAGECONFIG_APPEND} kms accessibility sm"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

PACKAGECONFIG_remove = "evdev"
