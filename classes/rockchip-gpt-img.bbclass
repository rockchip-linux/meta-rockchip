# Copyright (C) 2017 Fuzhou Rockchip Electronics Co., Ltd
# Copyright (C) 2017 Trevor Woerner <twoerner@gmail.com>
# Released under the MIT license (see COPYING.MIT for the terms)

inherit image_types

# Use an uncompressed ext4 by default as rootfs
IMG_ROOTFS_TYPE = "ext4"
IMG_ROOTFS = "${IMGDEPLOYDIR}/${IMAGE_BASENAME}-${MACHINE}.${IMG_ROOTFS_TYPE}"

# This image depends on the rootfs image
IMAGE_TYPEDEP_rockchip-gpt-img = "${IMG_ROOTFS_TYPE}"

GPTIMG = "${IMAGE_BASENAME}-${MACHINE}-gpt.img"
GPTIMG_SIZE ?= "4096"
BOOT_IMG = "${IMAGE_BASENAME}-${MACHINE}-boot.img"
IDBLOADER = "idbloader.img"

# Get From rk-binary loader
DDR_BIN = "ddr.bin"
LOADER_BIN = "loader.bin"
MINILOADER_BIN = "miniloader.bin"
ATF_BIN = "atf.bin"
UBOOT_IMG = "u-boot.img"
TRUST_IMG = "trust.img"

GPTIMG_APPEND_rk3036 = "console=tty1 console=ttyS2,115200n8 rw \
	root=PARTUUID=69dad710-2c rootfstype=ext4 init=/sbin/init"
GPTIMG_APPEND_rk3288 = "console=tty1 console=ttyS2,115200n8 rw \
	root=PARTUUID=69dad710-2c rootfstype=ext4 init=/sbin/init"
GPTIMG_APPEND_rk3328 = "earlycon=uart8250,mmio32,0xff130000 rw \
	root=PARTUUID=b921b045-1d rootwait rootfstype=ext4 init=/sbin/init rootwait"
GPTIMG_APPEND_rk3399 = "console=tty1 console=ttyFIQ0,1500000n8 rw \
	root=PARTUUID=b921b045-1d rootfstype=ext4 init=/sbin/init rootwait"

# default partitions [in Sectors]
# More info at http://rockchip.wikidot.com/partitions
LOADER1_SIZE = "8000"
RESERVED1_SIZE = "128"
RESERVED2_SIZE = "8192"
LOADER2_SIZE = "8192"
ATF_SIZE = "8192"
BOOT_SIZE = "229376"

# WORKROUND: miss recipeinfo
do_image_rockchip_gpt_img[depends] += " \
	rk-binary-loader:do_populate_lic \
	virtual/bootloader:do_populate_lic"

do_image_rockchip_gpt_img[depends] += " \
	parted-native:do_populate_sysroot \
	u-boot-mkimage-native:do_populate_sysroot \
	mtools-native:do_populate_sysroot \
	gptfdisk-native:do_populate_sysroot \
	dosfstools-native:do_populate_sysroot \
	rk-binary-native:do_populate_sysroot \
	rk-binary-loader:do_deploy \
	virtual/kernel:do_deploy \
	virtual/bootloader:do_deploy"

PER_CHIP_IMG_GENERATION_COMMAND_rk3036 = "generate_loader1_image"
PER_CHIP_IMG_GENERATION_COMMAND_rk3288 = "generate_loader1_image"
PER_CHIP_IMG_GENERATION_COMMAND_rk3328 = "generate_aarch64_loader_image"
PER_CHIP_IMG_GENERATION_COMMAND_rk3399 = "generate_aarch64_loader_image"

IMAGE_CMD_rockchip-gpt-img () {
	# Change to image directory
	cd ${DEPLOY_DIR_IMAGE}

	# Remove the existing image
	rm -f "${GPTIMG}"
	rm -f "${BOOT_IMG}"

	create_rk_image

	${PER_CHIP_IMG_GENERATION_COMMAND}

	cd ${DEPLOY_DIR_IMAGE}
	if [ -f ${WORKDIR}/${BOOT_IMG} ]; then
		cp ${WORKDIR}/${BOOT_IMG} ./
	fi
}

create_rk_image () {

	# last dd rootfs will extend gpt image to fit the size,
	# but this will overrite the backup table of GPT
	# will cause corruption error for GPT
	IMG_ROOTFS_SIZE=$(stat -L --format="%s" ${IMG_ROOTFS})

	GPTIMG_MIN_SIZE=$(expr $IMG_ROOTFS_SIZE + \( ${LOADER1_SIZE} + ${RESERVED1_SIZE} + ${RESERVED2_SIZE} + ${LOADER2_SIZE} + ${ATF_SIZE} + ${BOOT_SIZE} + 35 \) \* 512 )

	# add extra 10 MiB for safe area to keep out GPT backup table
	GPT_IMAGE_SIZE=$(expr $GPTIMG_MIN_SIZE \/ 1024 \/ 1024 + 10)

	# Initialize sdcard image file
	dd if=/dev/zero of=${GPTIMG} bs=1M count=0 seek=$GPT_IMAGE_SIZE

	# Create partition table
	parted -s ${GPTIMG} mklabel gpt

	# Create vendor defined partitions
	LOADER1_START=64
	RESERVED1_START=$(expr ${LOADER1_START} + ${LOADER1_SIZE})
	RESERVED2_START=$(expr ${RESERVED1_START} + ${RESERVED1_SIZE})
	LOADER2_START=$(expr ${RESERVED2_START} + ${RESERVED2_SIZE})
	ATF_START=$(expr ${LOADER2_START} + ${LOADER2_SIZE})
	BOOT_START=$(expr ${ATF_START} + ${ATF_SIZE})
	ROOTFS_START=$(expr ${BOOT_START} + ${BOOT_SIZE})

	parted -s ${GPTIMG} unit s mkpart loader1 ${LOADER1_START} $(expr ${RESERVED1_START} - 1)
	parted -s ${GPTIMG} unit s mkpart reserved1 ${RESERVED1_START} $(expr ${RESERVED2_START} - 1)
	parted -s ${GPTIMG} unit s mkpart reserved2 ${RESERVED2_START} $(expr ${LOADER2_START} - 1)
	parted -s ${GPTIMG} unit s mkpart loader2 ${LOADER2_START} $(expr ${ATF_START} - 1)
	parted -s ${GPTIMG} unit s mkpart atf ${ATF_START} $(expr ${BOOT_START} - 1)

	# Create boot partition and mark it as bootable
	parted -s ${GPTIMG} unit s mkpart boot ${BOOT_START} $(expr ${ROOTFS_START} - 1)
	parted -s ${GPTIMG} set 6 boot on

	# Create rootfs partition
	parted -s ${GPTIMG} -- unit s mkpart rootfs ${ROOTFS_START} -34s

	parted ${GPTIMG} print

	if [ "${DEFAULTTUNE}" = "aarch64" ];then
		ROOT_UUID="B921B045-1DF0-41C3-AF44-4C6F280D3FAE"
	else
		ROOT_UUID="69DAD710-2CE4-4E3C-B16C-21A1D49ABED3"
	fi

	# Change rootfs partuuid
	gdisk ${GPTIMG} <<EOF
x
c
7
${ROOT_UUID}
w
y
EOF

	# Delete the boot image to avoid trouble with the build cache
	rm -f ${WORKDIR}/${BOOT_IMG}

	# Create boot partition image
	BOOT_BLOCKS=$(LC_ALL=C parted -s ${GPTIMG} unit b print | awk '/ 6 / { print substr($4, 1, length($4 -1)) / 512 /2 }')
	BOOT_BLOCKS=$(expr $BOOT_BLOCKS / 63 \* 63)

	mkfs.vfat -n "boot" -S 512 -C ${WORKDIR}/${BOOT_IMG} $BOOT_BLOCKS
	mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin ::${KERNEL_IMAGETYPE}

	DTS_FILE=""
	DTBPATTERN="${KERNEL_IMAGETYPE}((-\w+)+\.dtb)"
	for DFILES in ${DEPLOY_DIR_IMAGE}/*; do
		DFILES=${DFILES##*/}
		if echo "${DFILES}" | grep -P $DTBPATTERN ; then
			[ -n "${DTS_FILE}" ] && bberror "Found multiple DTB under deploy dir, Please delete the unnecessary one."
			DTS_FILE=${DFILES#*${KERNEL_IMAGETYPE}-}
		fi
	done

	mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${DTS_FILE} ::${DTS_FILE}

	# Create extlinux config file
	cat >${WORKDIR}/extlinux.conf <<EOF
default yocto

label yocto
	kernel /${KERNEL_IMAGETYPE}
	devicetree /${DTS_FILE}
	append ${GPTIMG_APPEND}
EOF

	mmd -i ${WORKDIR}/${BOOT_IMG} ::/extlinux
	mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${WORKDIR}/extlinux.conf ::/extlinux/

	# Burn Boot Partition
	dd if=${WORKDIR}/${BOOT_IMG} of=${GPTIMG} conv=notrunc,fsync seek=${BOOT_START}

	# Burn Rootfs Partition
	dd if=${IMG_ROOTFS} of=${GPTIMG} conv=notrunc,fsync seek=${ROOTFS_START}

}

generate_loader1_image () {

	# Burn bootloader
	mkimage -n ${SOC_FAMILY} -T rksd -d ${DEPLOY_DIR_IMAGE}/${SPL_BINARY} ${WORKDIR}/${IDBLOADER}
	cat ${DEPLOY_DIR_IMAGE}/u-boot-${MACHINE}.bin >>${WORKDIR}/${IDBLOADER}
	dd if=${WORKDIR}/${IDBLOADER} of=${GPTIMG} conv=notrunc,fsync seek=64

}

generate_aarch64_loader_image () {
	LOADER1_START=64
	RESERVED1_START=$(expr ${LOADER1_START} + ${LOADER1_SIZE})
	RESERVED2_START=$(expr ${RESERVED1_START} + ${RESERVED1_SIZE})
	LOADER2_START=$(expr ${RESERVED2_START} + ${RESERVED2_SIZE})
	ATF_START=$(expr ${LOADER2_START} + ${LOADER2_SIZE})
	BOOT_START=$(expr ${ATF_START} + ${ATF_SIZE})
	ROOTFS_START=$(expr ${BOOT_START} + ${BOOT_SIZE})

	# Burn bootloader
	loaderimage --pack --uboot ${DEPLOY_DIR_IMAGE}/u-boot-${MACHINE}.bin ${WORKDIR}/${UBOOT_IMG} 0x200000

	mkimage -n ${SOC_FAMILY} -T rksd -d ${DEPLOY_DIR_IMAGE}/${DDR_BIN} ${WORKDIR}/${IDBLOADER}
	cat ${DEPLOY_DIR_IMAGE}/${MINILOADER_BIN} >>${WORKDIR}/${IDBLOADER}

	dd if=${WORKDIR}/${IDBLOADER} of=${GPTIMG} conv=notrunc,fsync seek=${LOADER1_START}
	dd if=${WORKDIR}/${UBOOT_IMG} of=${GPTIMG} conv=notrunc,fsync seek=${LOADER2_START}
	dd if=${DEPLOY_DIR_IMAGE}/${TRUST_IMG} of=${GPTIMG} conv=notrunc,fsync seek=${ATF_START}
}
