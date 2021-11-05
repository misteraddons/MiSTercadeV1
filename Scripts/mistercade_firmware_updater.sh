#!/bin/bash
# Copyright (c) 2021 MiSTer Addons <misteraddonstore@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# You can download the latest version of this script from:
# https://github.com/misteraddons/MiSTercade

# Version 1.0 - 2021-10-31 - First commit

FIRMWARE_DIR="/media/fat/Scripts/.mistercade/"
TEMP_DIR="/tmp/mistercade/"
NEW_FIRMWARE=0

if [ ! -d $FIRMWARE_DIR ]; then
    echo 'MiSTercade firmware directory not found, creating now...'
    mkdir $FIRMWARE_DIR
fi

if [ ! -d $TEMP_DIR ]; then
    #echo 'MiSTercade firmware directory not found, creating now...'
    mkdir $TEMP_DIR
fi

if [ ! -f /media/fat/Scripts/.mistercade/hid-flash_MiSTer ]; then
    echo 'MiSTercade firmware flasher not found, downloading now...'
    cd /media/fat/Scripts/.mistercade/
    wget -q https://github.com/misteraddons/MiSTercade/raw/main/MiSTercade%20Firmware/hid-flash_MiSTer
    echo 'Updating binary permissions...'
    chmod +x /media/fat/Scripts/.mistercade/hid-flash_MiSTer
fi

if [ ! -f /media/fat/Scripts/.mistercade/MiSTercade_FW.bin ]; then
    echo 'Latest MiSTercade firmware not found, downloading now...'
    cd /media/fat/Scripts/.mistercade/
    wget -q https://github.com/misteraddons/MiSTercade/raw/main/MiSTercade%20Firmware/MiSTercade_FW.bin
    NEW_FIRMWARE=1
#fi
#if [ -f /media/fat/Scripts/.mistercade/MiSTercade_FW.bin ]; then
else
    cd /tmp/mistercade/
    #rm *.bin
    #ls
    wget -q https://github.com/misteraddons/MiSTercade/raw/main/MiSTercade%20Firmware/MiSTercade_FW.bin
    #CURRENT_FIRMWARE=$FIRMWARE_DIR/MiSTercade_FW.bin
    #echo 'Current firmware checksum'
    #echo $CURRENT_CHECKSUM
    #NEW_FIRMWARE=$TEMP_DIR/MiSTercade_FW.bin
    #echo 'New firmware checksum'
    #echo $NEW_CHECKSUM
    #if [ $CURRENT_CHECKSUM != $NEW_CHECKSUM ]; then
    if ! cmp /media/fat/Scripts/.mistercade/MiSTercade_FW.bin /tmp/mistercade/MiSTercade_FW.bin; then
        echo 'New MiSTercade firmware found, downloading now...'
        rm /media/fat/Scripts/.mistercade/MiSTercade_FW.bin
        cp /tmp/mistercade/MiSTercade_FW.bin /media/fat/Scripts/.mistercade/MiSTercade_FW.bin
        NEW_FIRMWARE=1
    else
        echo 'No new MiSTercade firmware found.'
        NEW_FIRMWARE=0
        #exit 0
    fi
fi

#if [ NEW_FIRMWARE==1 ]; then
if (lsusb | grep -q "MCS MiSTer JAMMA Board") # Device not in DFU mode
then
    echo 'ERROR: MiSTercade is not in firmware upgrade mode. Please apply the pin jumper to the "STM32 DFU" pins and restart MiStercade.'
    exit 1
fi

if (lsusb | grep -q "1209:babe Generic brunofreitas.com STM32 HID Bootloader") # Device in DFU mode
then
    echo 'Device in DFU mode, updating firmware...'
    cd /media/fat/Scripts/.mistercade/
    ./hid-flash_MiSTer MiSTercade_FW.bin | grep -q 'Ok!' && echo 'Update complete! Please remove the "DFU Mode" pin jumper and restart'
    exit 0
else
    echo 'ERROR: MiSTercade is not in firmware upgrade mode. Please apply the pin jumper to the "STM32 DFU" pins and restart MiStercade.'
    exit 1
fi
#fi