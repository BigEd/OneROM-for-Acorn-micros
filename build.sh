#!/bin/bash

# The MMFS/MMFS2 build to use
#   U = Normal User Port
#   T = Normal User Port (Turbo interface)
#   P = Printer Port
# This needs to match your MMFS interface type
MMFS_BUILD=U

# Download URL of MMFS release ZIP to use
MMFS_URL="https://github.com/hoglet67/MMFS/releases/download/mmfs_1_61_0/mmfs_1_61_20261023_1133.zip"

# Download URL of Dominic's VFS ROM for Pi1MHz Domesday
VFS_URL="https://github.com/dp111/Pi1MHz/raw/refs/heads/master/firmware/Pi1MHz/VFS.rom"

# Download URL of MOS 3.20 Mega ROM (Y2K patched version from B-em)
MOS320_URL="https://github.com/stardot/b-em/raw/refs/heads/master/roms/os/mos320p.rom"

# Download URL of MOS 3.50 Mega ROM (Y2K patched version from B-em)
MOS350_URL="https://github.com/stardot/b-em/raw/refs/heads/master/roms/os/mos350p.rom"

# Download URL of Tom Seddon's Refreshed MOS Release ZIP
MOS_REF_VER="G"
MOS_REF_URL="https://github.com/tom-seddon/acorn_mos_refreshed/releases/download/mos-refreshed-${MOS_REF_VER}/mos-refreshed-${MOS_REF_VER}.zip"

# Path to OneROM CLI
ONEROM=onerom
case "$OSTYPE" in
  msys*|cygwin*|win32*)
    ONEROM="${ONEROM}.exe"
    ;;
esac
ONEROM_PATH=$(which ${ONEROM})
if [ -x "${ONEROM_PATH}" ] ; then
    echo "Using ${ONEROM_PATH}"
else
    echo "${ONEROM} executable needs to be on the PATH"
    exit
fi

# Download the required bits
DL=downloads
mkdir -p ${DL}
for URL in ${MMFS_URL} ${MOS320_URL} ${MOS350_URL} ${VFS_URL} ${MOS_REF_URL}
do
   echo "Downloading (if necessary) ${URL}"
   wget -P ${DL} -q -N ${URL}
done

# Create a build directory for artifacts
BUILD=build
mkdir -p ${BUILD}

# Unzip the various ZIP files to the build directory
unzip -q -o -d ${BUILD} ${DL}/$(basename ${MMFS_URL})
unzip -q -o -d ${BUILD} ${DL}/$(basename ${MOS_REF_URL}) '3[25]0G/*'

# Paths for the bits we need
MOS120_DANIEL_PATH=local/multios_120_daniel.bin
MOS120_IFEL_PATH=local/multios_120_ifel_108.bin
BLANK_PATH=local/blank.bin
MOS320_PATH=${DL}/$(basename ${MOS320_URL})
MOS350_PATH=${DL}/$(basename ${MOS350_URL})
VFS_PATH=${DL}/$(basename ${VFS_URL})
MOS320R_PATH=${BUILD}/320${MOS_REF_VER}/320${MOS_REF_VER}.bin
MOS350R_PATH=${BUILD}/350${MOS_REF_VER}/350${MOS_REF_VER}.bin

# Build slot images (each one is a full 231024 128KB ROM image)
#
# Slots 0..5 use MMFS
# Slots 6..7 use VFS
# Slots 8..13 use MMFSv2 instead of MMFS
# Slots 14..15 use VFS (identical to 6..7 so don't need to be programmed)

SLOT=0
for MMFS in MMFS MMFS2
do
    # Use Master MMFS build for MOS 320/350 derivatives
    MMFS_PATH=${BUILD}/${MMFS}/${MMFS_BUILD}/MAMMFS.rom

    # Slot 0: MOS 320p with MMFS in ROM 10
    # Slot 1: MOS 350p with MMFS in ROM 10
    for MOS in ${MOS320_PATH} ${MOS350_PATH}
    do
        BIN=${BUILD}/slot${SLOT}.bin
        cp ${MOS} ${BIN}
        dd status=none if=${MMFS_PATH} of=${BIN} bs=16K oseek=2 count=1 conv=notrunc
        SLOT=$((SLOT + 1))
    done

    # Slot 2: Tom Seddon's Refreshed MOS 320 with MMFS in ROM 10 and Basic Editor moved to ROM 14
    # Slot 3: Tom Seddon's Refreshed MOS 350 with MMFS in ROM 10 and Basic Editor moved to ROM 14
    for MOS in ${MOS320R_PATH} ${MOS350R_PATH}
    do
        BIN=${BUILD}/slot${SLOT}.bin
        cp ${MOS} ${BIN}
        dd status=none if=${BIN} of=${BUILD}/rom10.bin bs=16K skip=2 count=1
        dd status=none if=${MMFS_PATH} of=${BIN} bs=16K oseek=2 count=1 conv=notrunc
        dd status=none if=${BUILD}/rom10.bin of=${BIN} bs=16K oseek=6 count=1 conv=notrunc
        rm -f ${BUILD}/rom10.bin
        SLOT=$((SLOT + 1))
    done

    # Use Model B MMFS Sideways RAM Bootloaded build for OS 120 derivatives
    MMFS_PATH=${BUILD}/${MMFS}/${MMFS_BUILD}/ZMMFS.rom

    # Slot 4: OS 120 Daniel
    #
    # Starting image (in this git repo) has:
    #  8 - OS 1.20 with patches for Master
    #  9 - Blank
    # 10 - Blank
    # 11 - Blank
    # 12 - Blank
    # 13 - Blank
    # 14 - Blank
    # 15 - Basic II
    #
    # Final image has:
    #  8 - OS 1.20 with patches for Master
    #  9 - Blank
    # 10 - Blank
    # 11 - SWMMFS Bootloader (downloaded version)
    # 12 - Blank
    # 13 - Blank
    # 14 - Blank
    # 15 - Basic II
    MOS=${MOS120_DANIEL_PATH}
    BIN=${BUILD}/slot${SLOT}.bin
    cp ${MOS} ${BIN}
    dd status=none if=${MMFS_PATH} of=${BIN} bs=16K oseek=2 count=1 conv=notrunc
    SLOT=$((SLOT + 1))

    # Slot 5: OS 120 IFEL
    #
    # Starting image (in this git repo) has:
    #  8 - OS 1.20 with patches for Master
    #  9 - DFS 2.26
    # 10 - Exmon II 2.02
    # 11 - SWMMFS Boot Loader 1.45
    # 12 - Wordwise Plus 1.4F
    # 13 - Beebug Toolkit Plus
    # 14 - Basic II
    # 15 - Manager 1.07
    #
    # Final image has:
    #  8 - OS 1.20 with patches for Master
    #  9 - DFS 2.26
    # 10 - Blank
    # 11 - SWMMFS Boot Loader (downloaded version)
    # 12 - Blank
    # 13 - Blank
    # 14 - Basic II
    # 15 - Manager 1.07
    MOS=${MOS120_IFEL_PATH}
    BIN=${BUILD}/slot${SLOT}.bin
    cp ${MOS} ${BIN}
    dd status=none if=${BLANK_PATH} of=${BIN} bs=16K oseek=2 count=1 conv=notrunc
    dd status=none if=${MMFS_PATH}  of=${BIN} bs=16K oseek=3 count=1 conv=notrunc
    dd status=none if=${BLANK_PATH} of=${BIN} bs=16K oseek=4 count=1 conv=notrunc
    dd status=none if=${BLANK_PATH} of=${BIN} bs=16K oseek=5 count=1 conv=notrunc
    SLOT=$((SLOT + 1))

    # Slot 6: MOS 320p with VFS in ROM 10
    # Slot 7: MOS 350p with VFS in ROM 10
    for MOS in ${MOS320_PATH} ${MOS350_PATH}
    do
        BIN=${BUILD}/slot${SLOT}.bin
        cp ${MOS} ${BIN}
        dd status=none if=${VFS_PATH} of=${BIN} bs=16K oseek=2 count=1 conv=notrunc
        SLOT=$((SLOT + 1))
    done

done

${ONEROM} firmware build --board fire-28-d --plugin usb \
       --slot file=${BUILD}/slot0.bin,type=231024,cs1=0,label="MOS 320/Y2K/MMFS" \
       --slot file=${BUILD}/slot1.bin,type=231024,cs1=0,label="MOS 350/Y2K/MMFS" \
       --slot file=${BUILD}/slot2.bin,type=231024,cs1=0,label="MOS 320${MOS_REF_VER} Refreshed/MMFS" \
       --slot file=${BUILD}/slot3.bin,type=231024,cs1=0,label="MOS 350${MOS_REF_VER} Refreshed/MMFS" \
       --slot file=${BUILD}/slot4.bin,type=231024,cs1=0,label="OS 120 Daniel/MMFS" \
       --slot file=${BUILD}/slot5.bin,type=231024,cs1=0,label="OS 120 IFEL/MMFS" \
       --slot file=${BUILD}/slot6.bin,type=231024,cs1=0,label="MOS 320/Y2K/VFS for Domesday" \
       --slot file=${BUILD}/slot7.bin,type=231024,cs1=0,label="MOS 350/Y2K/VFS for Domesday" \
       --slot file=${BUILD}/slot8.bin,type=231024,cs1=0,label="MOS 320/Y2K/MMFS2" \
       --slot file=${BUILD}/slot9.bin,type=231024,cs1=0,label="MOS 350/Y2K/MMFS2" \
       --slot file=${BUILD}/slot10.bin,type=231024,cs1=0,label="MOS 320${MOS_REF_VER} Refreshed/MMFS2" \
       --slot file=${BUILD}/slot11.bin,type=231024,cs1=0,label="MOS 350${MOS_REF_VER} Refreshed/MMFS2" \
       --slot file=${BUILD}/slot12.bin,type=231024,cs1=0,label="OS 120 Daniel/MMFS2" \
       --slot file=${BUILD}/slot13.bin,type=231024,cs1=0,label="OS 120 IFEL/MMFS2" \
       --save-config ${BUILD}/master.cfg \
       --out ${BUILD}/master.bin

grep label build/master.cfg | cut -d: -f2 | nl -v 0

echo "To program:"
echo "${ONEROM} program --config ${BUILD}/master.cfg"
