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

# Remove any existing slot images
rm -f ${BUILD}/slot*

# Standard BBC Basic

echo "Downloading (if necessary) OS 1.20 bits"

MOS120_BASIC2_PATH=${DL}/os120_basic2.bin
wget -q -N -O ${MOS120_BASIC2_PATH} "https://tobylobster.github.io/rom_library/media/80/BASIC%20II%20%5Bvariant%201%5D.rom"

# Reconstruct a 128K Daniel OS 1.20 Image (OS, blank, blank, blank, blank, blank, BASIC, Manager)

MOS120_DANIEL_OS_PATH=${DL}/os120_daniel_os.bin
wget -q -N -O ${MOS120_DANIEL_OS_PATH} "https://tobylobster.github.io/rom_library/media/340/MOS%20v1.20%20%5Bvariant%207%5D%20%5B'Patched%20by%20DJameson%202016'%5D.rom"

MOS120_DANIEL_MGR_PATH=${DL}/os120_daniel_mgr.bin
wget -q -N -O ${MOS120_DANIEL_MGR_PATH} "https://tobylobster.github.io/rom_library/media/63/Advanced%20Disc%20Toolkit%20v2.00.rom"

MOS120_DANIEL_PATH=${BUILD}/os120_daniel.bin
truncate -s 131072 ${MOS120_DANIEL_PATH}
dd status=none if=${MOS120_DANIEL_OS_PATH}  of=${MOS120_DANIEL_PATH} bs=16K oseek=0 count=1 conv=notrunc
dd status=none if=${MOS120_BASIC2_PATH}     of=${MOS120_DANIEL_PATH} bs=16K oseek=6 count=1 conv=notrunc
dd status=none if=${MOS120_DANIEL_MGR_PATH} of=${MOS120_DANIEL_PATH} bs=16K oseek=7 count=1 conv=notrunc

# Reconstruct a 128K IFEL OS 1.20 Image (OS, blank, blank, blank, blank, blank, BASIC, Manager)

MOS120_IFEL_OS_PATH=${DL}/os120_ifel_os.bin
wget -q -N -O ${MOS120_IFEL_OS_PATH} "https://tobylobster.github.io/rom_library/media/340/MOS%20v1.20%20%5Bvariant%208%5D.rom"

MOS120_IFEL_MGR_PATH=${DL}/os120_ifel_mgr.bin
wget -q -N -O ${MOS120_IFEL_MGR_PATH} "https://tobylobster.github.io/rom_library/media/1078/Manager%20v1.08.rom"

MOS120_IFEL_PATH=${BUILD}/os120_ifel.bin
truncate -s 131072 ${MOS120_IFEL_PATH}
dd status=none if=${MOS120_IFEL_OS_PATH}  of=${MOS120_IFEL_PATH} bs=16K oseek=0 count=1 conv=notrunc
dd status=none if=${MOS120_BASIC2_PATH}   of=${MOS120_IFEL_PATH} bs=16K oseek=6 count=1 conv=notrunc
dd status=none if=${MOS120_IFEL_MGR_PATH} of=${MOS120_IFEL_PATH} bs=16K oseek=7 count=1 conv=notrunc

# Unzip the various ZIP files to the build directory
unzip -q -o -d ${BUILD} ${DL}/$(basename ${MMFS_URL})
unzip -q -o -d ${BUILD} ${DL}/$(basename ${MOS_REF_URL}) '3[25]0G/*'

# Paths for the bits we need

BLANK_PATH=local/blank.bin
MOS320_PATH=${DL}/$(basename ${MOS320_URL})
MOS350_PATH=${DL}/$(basename ${MOS350_URL})
VFS_PATH=${DL}/$(basename ${VFS_URL})
MOS320R_PATH=${BUILD}/320${MOS_REF_VER}/320${MOS_REF_VER}.bin
MOS350R_PATH=${BUILD}/350${MOS_REF_VER}/350${MOS_REF_VER}.bin

# Build slot images (each one is a full 231024 128KB ROM image)
#
# Jumper 3 and 2 select the main OS (320, 350, 120, Custom)
# Jumper 1 is Original (ish) vs Refreshed
# Jumper 0 is MMFS vs MMFS2
#
#  0  "MOS 320/Y2K/MMFS"
#  1  "MOS 320/Y2K/MMFS2"
#  2  "MOS 320G Refreshed/MMFS"
#  3  "MOS 320G Refreshed/MMFS2"
#  4  "MOS 350/Y2K/MMFS"
#  5  "MOS 350/Y2K/MMFS2"
#  6  "MOS 350G Refreshed/MMFS"
#  7  "MOS 350G Refreshed/MMFS2"
#  8  "OS 120 Daniel/MMFS"
#  9  "OS 120 Daniel/MMFS2"
# 10  "OS 120 IFEL/MMFS"
# 11  "OS 120 IFEL/MMFS2"
# 12  "MOS 320/Y2K/VFS for Domesday"
# 13  "MOS 350/Y2K/VFS for Domesday"

# Construct the PROG command on the fly
PROG="${ONEROM} firmware build --board fire-28-d --plugin usb --save-config ${BUILD}/master.cfg --out ${BUILD}/master.bin"

for SLOT in $(seq 0 13)
do

    # Default ROM type
    TYPE="231024,cs1=0"

    # This doesn't work because there isn't a way in the CLI to set allow_cs_ignore
    #case "${SLOT}" in
    #    8|9|10|11)
    #        TYPE="23512,cs1=0,cs2=ignore"
    #    ;;
    #esac

    # Setup base MOS
    case "${SLOT}" in
        0|1|12)
            MOS=${MOS320_PATH}
            LABEL="MOS 320/Y2K"
            ;;
        2|3)
            MOS=${MOS320R_PATH}
            LABEL="MOS 320${MOS_REF_VER} Refreshed"
            ;;
        4|5|13)
            MOS=${MOS350_PATH}
            LABEL="MOS 350/Y2K"
            ;;
        6|7)
            MOS=${MOS350R_PATH}
            LABEL="MOS 350${MOS_REF_VER} Refreshed"
            ;;
        8|9)
            MOS=${MOS120_DANIEL_PATH}
            LABEL="OS 120 Daniel"
            ;;
        10|11)
            MOS=${MOS120_IFEL_PATH}
            LABEL="OS 120 IFEL"
            ;;
    esac

    # Setup the FS
    case "${SLOT}" in
        0|2|4|6)
            FS_PATH=${BUILD}/MMFS/${MMFS_BUILD}/MAMMFS.rom
            LABEL="${LABEL}/MMFS"
            ;;
        1|3|5|7)
            FS_PATH=${BUILD}/MMFS2/${MMFS_BUILD}/MAMMFS.rom
            LABEL="${LABEL}/MMFS2"
            ;;
        8|10)
            FS_PATH=${BUILD}/MMFS/${MMFS_BUILD}/ZMMFS.rom
            LABEL="${LABEL}/SWMMFS"
            ;;
        9|11)
            FS_PATH=${BUILD}/MMFS2/${MMFS_BUILD}/ZMMFS.rom
            LABEL="${LABEL}/SWMMFS2"
            ;;
        12|13)
            FS_PATH=${VFS_PATH}
            LABEL="${LABEL}/VFS for Domesday"
            ;;
    esac

    # Append the slot command
    PROG="${PROG} --slot file=${BUILD}/slot${SLOT}.bin,type=${TYPE},label='${LABEL}'"

    # Create the output ilename
    BIN=${BUILD}/slot${SLOT}.bin

    # Copy the base MOS
    cp ${MOS} ${BIN}

    # Custom actions
    case "${SLOT}" in
        # Tom Seddon's Refreshed MOS
        2|3|6|7)
            # Backup Basic Editor in slot 10
            dd status=none if=${BIN} of=${BUILD}/rom10.bin bs=16K skip=2 count=1
            # Move it to slot 14
            dd status=none if=${BUILD}/rom10.bin of=${BIN} bs=16K oseek=6 count=1 conv=notrunc
            # Tidy up
            rm -f ${BUILD}/rom10.bin
            ;;
    esac

    # Inject the filesystem into slot 10 in all builds
    dd status=none if=${FS_PATH} of=${BIN} bs=16K oseek=2 count=1 conv=notrunc

done

echo $PROG

eval "${PROG}"

grep label build/master.cfg | cut -d: -f2 | nl -v 0

echo "To program:"
echo "${ONEROM} program --config ${BUILD}/master.cfg"
