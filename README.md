# MiSTercade
 MiSTer FPGA JAMMA adapter

This repository is reserved for MiSTercade testers
Choose a MiSTer.ini (15 kHz or 31 kHz) and rename it to MiSTer.ini
- 31 kHz is untested
Copy these files to your MiSTer's micro SD card, overwriting existing files

Button mapping is as follows:
1 2 3    B A R
4 5 6    Y X L
Coin = Select
Start = Start
Menu/OSD = Down + Start
Feel free to remap as needed

Several core input mappings have been done, but not all. Many of the arcade cores have R or L mapped to P2 start and coin. Fixing those is outside the scope of this project, but I'd like to standardize them to the above mapping, if developers permit. MAME does this well and I think it's the way to go.

Should the controller firmware need updating do as follows:
Put hid-flash_MiSTer and firmware files in the root of micro SD card
Toggle "STM32 DFU" dip switch to on
Toggle "USB Controls" dip switch to off then back to on
Plug in USB keyboard
Press F9 on main menu of MiSTer
username: root
password: 1
Enter the following commands:
cd /media/fat/
lsusb
(Check for 1209:babe in the device list - this is the bootloader for the STM32 microcontroller)
hid-flash_MiSTer STM32_2P_Encoder_50ms_debounce.bin
exit
Press F12 to return to main menu
Turn STM32 DFU dip switch off
Toggle "USB Controls" dip switch to off then back to on
