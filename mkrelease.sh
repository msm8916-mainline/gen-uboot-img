#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2024 Nikita Travkin <nikita@trvn.ru>

LK2ND_DIR=../lk2nd
QHYPSTUB_DIR=../qhypstub
LINUX_DIR=../linux
UBOOT_DIR=../u-boot

describe_version() {
	old_dir=$PWD
	cd $1
	$LK2ND_DIR/lk2nd/scripts/describe-version.sh
	cd $old_dir
}

describe_all() {
	printf "Components:\n"
	printf "  lk2nd    - %s\n" $(describe_version $LK2ND_DIR)
	printf "  qhypstub - %s\n" $(describe_version $QHYPSTUB_DIR)
	printf "  u-boot   - %s\n" $(describe_version $UBOOT_DIR)
	printf "  linux    - %s\n" $(describe_version $LINUX_DIR)
}

generate_tag() {
	linux_tag=$(git -C $LINUX_DIR describe --tags --abbrev=0)
	date=$(date "+%Y%m%d")
	echo "$date-$linux_tag"
}

sign_everything() {
	old_dir=$PWD
	cd $1
	sha256sum -- * > sha256sums.txt
	gpg --yes --detach-sign sha256sums.txt
	cd $old_dir
}

TAG=$(generate_tag)

echo "Generating \'$TAG\'"

BUILD_DIR="$PWD/release/$TAG/build"
BLOB_DIR="$PWD/release/$TAG/artifacts"

make -j$(nproc) BUILD_DIR="$BUILD_DIR"
mkdir -p "$BLOB_DIR"

cp \
	"$BUILD_DIR/combined.img" \
	"$BUILD_DIR/lk2nd.img" \
	"$BUILD_DIR/qhypstub.bin" \
	"$BUILD_DIR/thirdstage.ext2" \
	"$BLOB_DIR"

sign_everything "$BLOB_DIR"

git tag -s -a -m "$TAG" -m "$(describe_all)" "$TAG"


echo ==========================================================
echo Done building!
echo Now you can push the tag: "git push origin $TAG"
echo and upload the artifacts from "$BLOB_DIR"
echo ==========================================================

