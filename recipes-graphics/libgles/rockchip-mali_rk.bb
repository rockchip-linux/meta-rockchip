DESCRIPTION = "GLES libraries for Rockchip SoCs for a family of Mali GPU"
SECTION = "libs"
LICENSE = "CLOSED"
BB_STRICT_CHECKSUM = "0"

COMPATIBLE_MACHINE = "(rk3036|rk3066|rk3288|rk3328|rk3399)"

DEPENDS = "libdrm mesa patchelf-native"

PROVIDES += "virtual/egl virtual/libgles1 virtual/libgles2 virtual/libopencl libgbm"
PROVIDES += "${@bb.utils.contains("DISTRO_FEATURES", "wayland", " virtual/libwayland-egl", " ", d)}"

USE_X11 = "${@bb.utils.contains("DISTRO_FEATURES", "x11", "yes", "no", d)}"
USE_WL = "${@bb.utils.contains("DISTRO_FEATURES", "wayland", "yes", "no", d)}"

MALI_TUNE = ""
MALI_NAME = ""

MALI_X11_rk3036 = "libmali-utgard-400-r7p0.so"
MALI_WAYLAND_rk3036 = "libmali-utgard-400-r7p0-wayland.so"
MALI_GBM_rk3036 = "libmali-utgard-400-r7p0-gbm.so"

MALI_X11_rk3066 = "libmali-utgard-400-r7p0.so"
MALI_WAYLAND_rk3066 = "libmali-utgard-400-r7p0-wayland.so"
MALI_GBM_rk3066 = "libmali-utgard-400-r7p0-gbm.so"

MALI_X11_rk3288 = "libmali-midgard-t76x-r14p0-r0p0.so"
MALI_WAYLAND_rk3288 = "libmali-midgard-t76x-r14p0-r0p0-wayland.so "
MALI_GBM_rk3288 = "libmali-midgard-t76x-r14p0-r0p0-gbm.so "

MALI_X11_rk3328 = "libmali-utgard-450-r7p0.so"
MALI_WAYLAND_rk3328 = "libmali-utgard-450-r7p0-wayland.so"
MALI_GBM_rk3328 = "libmali-utgard-450-r7p0-gbm.so"

MALI_X11_rk3399 = "libmali-midgard-t86x-r14p0.so"
MALI_WAYLAND_rk3399 = "libmali-midgard-t86x-r14p0-wayland.so"
MALI_GBM_rk3399 = "libmali-midgard-t86x-r14p0-gbm.so"

# There's only hardfp version available
python __anonymous() {
    tunes = d.getVar("TUNE_FEATURES", True)
    if not tunes:
        return

    if tunes == "aarch64":
        d.setVar("MALI_TUNE", "aarch64-linux-gnu")
    else:
        d.setVar("MALI_TUNE", "arm-linux-gnueabihf")

    use_x11 = d.getVar("USE_X11", True)
    use_wayland = d.getVar("USE_WL", True)
    if use_wayland == "yes":
        d.setVar("MALI_NAME", d.getVar("MALI_WAYLAND", True))
    elif use_x11 == "yes":
        d.setVar("MALI_NAME", d.getVar("MALI_X11", True))
    else:
        d.setVar("MALI_NAME", d.getVar("MALI_GBM", True))

    if tunes == "aarch64":
        return
    if "callconvention-hard" not in tunes:
        pkgn = d.getVar("PN", True)
        pkgv = d.getVar("PV", True)
        raise bb.parse.SkipPackage("%s-%s ONLY supports hardfp mode for now" % (pkgn, pkgv))
}

S = "${WORKDIR}/"
SRC_URI = "https://github.com/rockchip-linux/libmali/raw/29mirror/lib/${MALI_TUNE}/${MALI_NAME}"

INSANE_SKIP_${PN} = "already-stripped ldflags dev-so"

INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_PACKAGE_STRIP = "1"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install () {
	# Create MALI manifest
	install -m 755 -d ${D}/${libdir}
	install ${S}/${MALI_NAME} ${D}/${libdir}/libMali.so

	ln -sf libMali.so ${D}/${libdir}/libEGL.so
	ln -sf libMali.so ${D}/${libdir}/libEGL.so.1
	ln -sf libMali.so ${D}/${libdir}/libGLESv1_CM.so
	ln -sf libMali.so ${D}/${libdir}/libGLESv1_CM.so.1
	ln -sf libMali.so ${D}/${libdir}/libGLESv2.so
	ln -sf libMali.so ${D}/${libdir}/libGLESv2.so.2
	ln -sf libMali.so ${D}/${libdir}/libOpenCL.so
	ln -sf libMali.so ${D}/${libdir}/libOpenCL.so.1
	ln -sf libMali.so ${D}/${libdir}/libgbm.so
	ln -sf libMali.so ${D}/${libdir}/libgbm.so.1

	if [ "${USE_WL}" = "yes" ]; then
		ln -sf libMali.so ${D}/${libdir}/libwayland-egl.so
		ln -sf libMali.so ${D}/${libdir}/libwayland-egl.so.1
	fi

	# Workaround: libMali.so provided by rk having no SONAME field in itroot
	# so add it to fix rdepends problems
	patchelf --set-soname "libEGL.so.1" ${D}/${libdir}/libMali.so
}

PACKAGES = "${PN}"
FILES_${PN} += "${libdir}/*.so"

RREPLACES_${PN} = "libegl libgles1 libglesv1-cm1 libgles2 libglesv2-2 libgbm"
RCONFLICTS_${PN} = "libegl libgles1 libglesv1-cm1 libgles2 libglesv2-2 libgbm"
RPROVIDES_${PN} += "libegl libgles1 libglesv1-cm1 libgles2 libglesv2-2 libgbm"
