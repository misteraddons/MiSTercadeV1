# MiSTercade
 MiSTer FPGA JAMMA adapter

## Installation
* Choose a MiSTer.ini (15 kHz or 31 kHz) and rename it to MiSTer.ini
* Download the files from Github
* Unzip one of the button mappings from /config/inputs folder - Note only difference in menu button combination (down + start vs B1 + B6)
* Copy input mapping files to Micro SD card
* Copy these files to your MiSTer's micro SD card, overwriting existing files
* Toggle SW0 on DE10-nano (one of the 4 large switches near the GPIO header) towards the center of the board. SW1-3 should remain off (towards edge of board)
* Plug MiSTercade PCB into top of DE10-nano, mating all pin headers
* Install USB bridge to both the DE10-nano and MiSTercade PCB
* Plug JAMMA Connector onto MiSTercade edge, ensuring correct orientation and pin alignment (ensure GND, and Voltage pins are correct)

## Controls
### Button mapping:
``` 
1 2 3    A B X
4 5 6    Y L -
Coin = R
Start = Start
Menu/OSD = Down + Start OR B1 + B6 (depending on which zip file you extract)
```
* NOTE: If you choose B1 + B6 menu button combo, you will not be able to activate autofire on B1 or B6
* NOTE: If you choose Down + Start menu button combo, you will not be able to use freeplay 
* 6 button mapping not currently supported by default so 6 button games will have their own per-game input mappings
* Feel free to remap as needed

### Updating controller firmware:
Should the controller firmware need updating do as follows:
* Put hid-flash_MiSTer and firmware files in the root of micro SD card
* Toggle Install pin jumper on "STM32 DFU" header pins
* Plug in USB keyboard
* Power on MiSTer
* Press F9 on main menu of MiSTer to enter terminal (or ssh)
* username: root
* password: 1
* Enter the following commands to check for proper hardware ID
```
lsusb
```
* Check for 1209:babe in the device list - this is the STM32 microcontroller bootloader
* Enter the following commands to update the firmware
```
cd /media/fat
./hid-flash_MiSTer firmwarename.bin
```
* Remove STM32 DFU Jumper
* Restart MiSTercade
* Press F9 on main menu of MiSTer
* username: root
* password: 1
* Enter the following commands to check for proper hardware ID
```
lsusb
```
* Check for 8888:8888 in the device list - this is the STM32 microcontroller firmware

## Sound
Sound varies wildly across cores. The best thing to do is to set the blue potentiometer low enough so most cores don't clip, and amplifier is still loud enough.
Volume can be adjusted using the protruding potentiometer, or in the menu as follows:
* Bring up the OSD Menu by pressing down + start (or whatever you mapped it to)
* Press left
* Adjust core volume or main volume
* (Core volume settings are saved to the SD card for future use)

* Alternatively, use the Audio Normalization Scripts https://github.com/misteraddons/normalize_audio_scripts

## Video
RGB Video levels are ~3V

## SNAC
Built-in SNAC is intended for light guns, but works with controllers as well. The usual caveats with SNAC apply - can't control OSD menu, 1 player, no native arcade controls, etc.

## Built-in Switches
| DIP Switch | Left Position | Right Position |
| --- | --- | --- |
| AMP STBY | Audio Amp Active | Audio Amp Standby |
| C1=C2 | Coin signals separate | Coin signals merged (candy cabinets) |
| P1 FREE | Freeplay Off | Freeplay On |
| P2 FREE | Freeplay Off | Freeplay On |

| Toggle Switch | Left Position | Right Position |
| --- | --- | --- |
| Audio Route | Onboard Volume Adjustment | Remote Volume Adjustment |
| CHAMMA | Buttons 5 and 6 on JAMMA Pins 26 and 27 | Buttons 5 and 6 not on JAMMA edge |


| Pin Jumpers | Left Position | Right Position |
| --- | --- | --- |
| STM32 DFU | Firmware Upgrade Mode | - |
| P2B8 / CC | Enable P2B8 (requires alt FW) | Enable Coin Counter (stock FW) |
| CSync | TTL CSync Level | 75ohm CSync Level |
| HD15 P9 5V | 5V to VGA Pin 9 for monitors that require this (rare) | - |
