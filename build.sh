#!/bin/bash

### Prema Chand Alugu (premaca@gmail.com)
### Shivam Desai (shivamdesaixda@gmail.com)
### A custom build script to build zImage & DTB(Anykernel2 method)

set -e

V="alpha"

#CI stuff
sudo apt-get update --quiet
# This gets updates for server/ci
sudo apt-get install --yes build-essential bc kernel-package libncurses5-dev bzip2 liblz4-tool git curl

chmod a+x ./*
## Copy this script inside the kernel directory
KERNEL_DIR=$PWD
KERNEL_TOOLCHAIN=$KERNEL_DIR/toolchain/bin/aarch64-linux-android-
mkdir -p toolchain
if [ ! -d "toolchain/.git" ]; then
git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 --single-branch toolchain
fi
KERNEL_DEFCONFIG=cedric_defconfig
DTBTOOL=$KERNEL_DIR/Dtbtool/
JOBS="-j$(nproc --all)"
ANY_KERNEL2_DIR=$KERNEL_DIR/AnyKernel2/
FINAL_KERNEL_ZIP=8.x_$V-64bit_Cedric.zip
export ZIP_NAME=$FINAL_KERNEL_ZIP
export LOCALVERSION="_$V"
MAKE="./makeparallel"

BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo "**** Setting Toolchain ****"
export CROSS_COMPILE=$KERNEL_TOOLCHAIN
export ARCH=arm64
export SUBARCH=arm64

echo "**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****"
echo -e "$blue***********************************************"
echo "          BUILDING KERNEL          "
echo -e "***********************************************$nocol"
make $KERNEL_DEFCONFIG
make $JOBS

echo -e "$blue***********************************************"
echo "          GENERATING DT.img          "
echo -e "***********************************************$nocol"
$DTBTOOL/dtbToolCM -2 -o $KERNEL_DIR/arch/arm64/boot/dtb -s 2048 -p $KERNEL_DIR/scripts/dtc/ $KERNEL_DIR/arch/arm64/boot/dts/qcom/

echo "**** Verify zImage & dtb ****"
ls $KERNEL_DIR/arch/arm64/boot/Image.gz
ls $KERNEL_DIR/arch/arm64/boot/dtb

echo "**** Verifying Anyernel2 Directory ****"
ls $ANY_KERNEL2_DIR
echo "**** Removing leftovers ****"
rm -rf $ANY_KERNEL2_DIR/dtb
rm -rf $ANY_KERNEL2_DIR/Image.gz
rm -rf $ANY_KERNEL2_DIR/$FINAL_KERNEL_ZIP

echo "**** Copying zImage ****"
cp $KERNEL_DIR/arch/arm64/boot/Image.gz $ANY_KERNEL2_DIR/
echo "**** Copying dtb ****"
cp $KERNEL_DIR/arch/arm64/boot/dtb $ANY_KERNEL2_DIR/

echo "**** Time to zip up! ****"
cd $ANY_KERNEL2_DIR/
zip -r9 $FINAL_KERNEL_ZIP * -x README $FINAL_KERNEL_ZIP
rm -rf $KERNEL_DIR/Builds/$FINAL_KERNEL_ZIP
mkdir -p Builds
cp $ANY_KERNEL2_DIR/$FINAL_KERNEL_ZIP $KERNEL_DIR/Builds/$FINAL_KERNEL_ZIP

echo "**** Good Bye!! ****"
cd $KERNEL_DIR
rm -rf arch/arm64/boot/dtb
rm -rf $ANY_KERNEL2_DIR/$FINAL_KERNEL_ZIP
rm -rf $ANY_KERNEL2_DIR/Image.gz
rm -rf $ANY_KERNEL2_DIR/dtb

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"

cd ./Builds/
