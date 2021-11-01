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

if (lsusb | grep -q "MCS MiSTer JAMMA Board") # Device not in DFU mode
then
    echo 'ERROR: MiSTercade is not in firmware upgrade mode. Please apply the pin jumper to the "STM32 DFU" pins and restart MiStercade.'
    exit 1
fi

if (lsusb | grep -q "1209:babe Generic brunofreitas.com STM32 HID Bootloader") # Device in DFU mode
then
    echo 'Device in DFU mode, updating firmware...'
    /media/fat/MiSTercade\ Firmware/hid-flash_MiSTer /media/fat//MiSTercade\ Firmware/MiSTercade_latest.bin | grep -q 'Ok!' && echo 'Update complete! Please remove the "DFU Mode" pin jumper and restart'
    exit 0
else
    echo 'ERROR: MiSTercade is not in firmware upgrade mode. Please apply the pin jumper to the "STM32 DFU" pins and restart MiStercade.'
    exit 1
fi