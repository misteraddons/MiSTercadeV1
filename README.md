# MiSTercade
 MiSTer FPGA JAMMA adapter

## Installation
* Download a [MiSTer.ini file](https://github.com/misteraddons/mister_ini/tree/main/MiSTercade%20V1) that matches your cabinet's resolution and orientation, and place it in the main folder of your MiSTer SD card.
* Modify or create the "downloader.ini" file on your MiSTer SD card, by including this section of code. This will ensure the correct mappings for all arcade games are downloaded and updated automatically!
```
[misteraddons/mistercade_v2_mappings]
db_url = https://raw.githubusercontent.com/misteraddons/mistercade_v2_mappings/db/db.json.zip
allow_delete = 0
verbose = true
```
* Toggle SW0 on DE10-nano (one of the 4 large switches near the GPIO header) towards the center of the board. SW1-3 should remain off (towards edge of board)
* Plug MiSTercade PCB into top of DE10-nano, mating all pin headers
* Install USB bridge to both the DE10-nano and MiSTercade PCB
* Plug JAMMA Connector onto MiSTercade edge, ensuring correct orientation and pin alignment (ensure GND, and Voltage pins are correct)

## Controls
### Button mapping:
``` 
1 2 3    A B R
4 5 6    X Y L
Coin = R
Start = Start
Menu/OSD = Down + Start OR B1 + B6 (depending on which zip file you extract)
```
* NOTE: If you choose B1 + B6 menu button combo, you will not be able to activate autofire on B1 or B6
* NOTE: If you choose Down + Start menu button combo, you will not be able to use freeplay 
* 6 button mapping not currently supported by default so 6 button games will have their own per-game input mappings
* Feel free to remap as needed

## Twin Stick Games
* There are several twin stick games on MiSTer. There are 2 general configuration styles: mapping and OSD setting. The included map files are set for twin stick play, and the cfg files enable twin stick on their corresponding games.
* Tank sticks aren't easily supported as they require twin sticks with triggers
* Twin stick games are mapped for both button and second stick shooting direction as follows:
```
B1    B2    B3       UP    LEFT  RIGHT
B4    B5    B6       DOWN   -      - 
```

| Game | Twin Stick Mode |
| --- | --- |
| Black Widow | input mapping (1P only) |
| Crazy Climber | input mapping (1P only) |
| Crazy Climber 2 | input mapping (1P only) |
| Inferno | input mapping (1P only) + [OSD option] "Aim+fire: On" |
| Lost Tomb | [OSD option] Fire Mode: Second Joystick |
| Mars | [OSD option] Fire Mode: Second Joystick |
| Minefield | [OSD option] Fire Mode: Second Joystick |
| Rescue | [OSD option] Fire Mode: Second Joystick |
| Robotron 2084 | [OSD option] Fire Mode: Second Joystick |
| Star Guards | input mapping (1P only) |
| Water Match | input mapping (1P only) |


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
