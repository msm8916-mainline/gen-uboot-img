# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2024 Nikita Travkin <nikita@trvn.ru>

ROOT_DIR	:= $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

CROSS_COMPILE	 ?= aarch64-linux-gnu-
CROSS_COMPILE_32 ?= arm-none-eabi-

LK2ND_DIR 	?= ../lk2nd
QHYPSTUB_DIR 	?= ../qhypstub
LINUX_DIR 	?= ../linux
UBOOT_DIR	?= ../u-boot

BUILD_DIR	?= $(ROOT_DIR)/build

LK2ND_PROJECT	?= lk2nd-msm8916
LINUX_ARCH	?= arm64
LINUX_DEFCONFIG	?= msm8916_defconfig

FS_IMG_SIZE	?= 4M

all: $(BUILD_DIR)/combined.img

$(BUILD_DIR)/combined.img: $(BUILD_DIR)/thirdstage.ext2 $(BUILD_DIR)/qhypstub.bin $(BUILD_DIR)/lk2nd.img
	@mkdir -p $(dir $@)
	cp $(BUILD_DIR)/lk2nd.img $@
	truncate -s 508K $@
	cat $(BUILD_DIR)/qhypstub.bin >> $@
	truncate -s 512K $@
	cat $(BUILD_DIR)/thirdstage.ext2 >> $@

.PHONY: $(BUILD_DIR)/u-boot-nodtb.bin.gz $(BUILD_DIR)/qhypstub.bin $(BUILD_DIR)/lk2nd.img $(BUILD_DIR)/dtbs $(BUILD_DIR)/thirdstage.ext2

$(BUILD_DIR)/thirdstage.ext2: $(BUILD_DIR)/u-boot-nodtb.bin.gz $(BUILD_DIR)/dtbs extlinux/extlinux.conf
	@mkdir -p $(BUILD_DIR)/thirdstage
	cp $(BUILD_DIR)/u-boot-nodtb.bin.gz $(BUILD_DIR)/thirdstage
	mkdir -p $(BUILD_DIR)/thirdstage/dtbs/qcom
	cp $(BUILD_DIR)/dtbs/qcom/msm8*16* $(BUILD_DIR)/dtbs/qcom/apq8016* $(BUILD_DIR)/thirdstage/dtbs/qcom
	cp -r extlinux/ $(BUILD_DIR)/thirdstage
	mke2fs -t ext2 -F -d $(BUILD_DIR)/thirdstage $@ $(FS_IMG_SIZE)

$(BUILD_DIR)/u-boot-nodtb.bin.gz:
	@mkdir -p $(dir $@)
	$(MAKE) -C $(UBOOT_DIR) CROSS_COMPILE=$(CROSS_COMPILE) O=$(BUILD_DIR)/u-boot qcom_defconfig phone.config
	$(MAKE) -C $(UBOOT_DIR) CROSS_COMPILE=$(CROSS_COMPILE) O=$(BUILD_DIR)/u-boot u-boot-nodtb.bin
	gzip -9 -c $(BUILD_DIR)/u-boot/u-boot-nodtb.bin > $@

$(BUILD_DIR)/qhypstub.bin:
	@mkdir -p $(dir $@)
	$(MAKE) -C $(QHYPSTUB_DIR) CROSS_COMPILE=$(CROSS_COMPILE)
	cp $(QHYPSTUB_DIR)/qhypstub.bin $@


$(BUILD_DIR)/lk2nd.img:
	@mkdir -p $(dir $@)
	$(MAKE) -C $(LK2ND_DIR) TOOLCHAIN_PREFIX=$(CROSS_COMPILE_32) BOOTLOADER_OUT=$(BUILD_DIR)/lk2nd APPSBOOTOUT_DIR=$(BUILD_DIR)/lk2nd $(LK2ND_PROJECT)
	cp $(BUILD_DIR)/lk2nd/build-$(LK2ND_PROJECT)/lk2nd.img $@

$(BUILD_DIR)/dtbs:
	@mkdir -p $(dir $@)
	$(MAKE) -C $(LINUX_DIR) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=$(LINUX_ARCH) O=$(BUILD_DIR)/linux $(LINUX_DEFCONFIG)
	$(MAKE) -C $(LINUX_DIR) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=$(LINUX_ARCH) O=$(BUILD_DIR)/linux dtbs
	$(MAKE) -C $(LINUX_DIR) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=$(LINUX_ARCH) O=$(BUILD_DIR)/linux dtbs_install INSTALL_DTBS_PATH=$@

