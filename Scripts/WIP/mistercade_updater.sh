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

#=========   USER OPTIONS   =========
#Base directory for all script’s tasks, "/media/fat" for SD root, "/media/usb0" for USB drive root.
BASE_PATH="/media/fat"

#Directories where all core categories will be downloaded.
#declare -A CORE_CATEGORY_PATHS
MISTER_INI_PATH=$BASE_PATH
CONFIG_PATH="$BASE_PATH/config"
INPUTs_PATH="$BASE_PATH/config/inputs"
U-BOOT_PATH="$BASE_PATH/linux"

#Specifies if old files (cores, main MiSTer executable, menu, SD-Installer, etc.) will be deleted as part of an update.
DELETE_OLD_FILES="true"

#========= ADVANCED OPTIONS =========
#ALLOW_INSECURE_SSL="true" will check if SSL certificate verification (see https://curl.haxx.se/docs/sslcerts.html )
#is working (CA certificates installed) and when it's working it will use this feature for safe curl HTTPS downloads,
#otherwise it will use --insecure option for disabling SSL certificate verification.
#If CA certificates aren't installed it's advised to install them (i.e. using security_fixes.sh).
#ALLOW_INSECURE_SSL="false" will never use --insecure option and if CA certificates aren't installed
#any download will fail.
ALLOW_INSECURE_SSL="true"
CURL_RETRY="--connect-timeout 15 --max-time 120 --retry 3 --retry-delay 5"
MISTERCADE_URL="https://github.com/misteraddons/MiSTercade"
SCRIPTS_PATH="Scripts"
WORK_PATH="/media/fat/$SCRIPTS_PATH/.mistercade_updater"
#Comment (or uncomment) next lines if you don't want (or want) to update/download from additional repositories (i.e. Scaler filters and Gameboy palettes) each time
ADDITIONAL_REPOSITORIES=(
	"https://github.com/MiSTer-devel/Filters_MiSTer/tree/master/Filters|txt|$BASE_PATH/Filters"
)
UNRAR_DEBS_URL="http://http.us.debian.org/debian/pool/non-free/u/unrar-nonfree"
#Uncomment this if you want the script to sync the system date and time with a NTP server
#NTP_SERVER="0.pool.ntp.org"
TEMP_PATH="/tmp"

#========= CODE STARTS HERE =========

# Create temp directory
if [ ! -d /media/fat/tmp/mistercade/ ]; then
    echo 'MiSTercade firmware directory not found, creating now...'
    mkdir /media/fat/tmp/mistercade/
fi

# Clear /tmp/mistercade
#cd /media/fat/tmp/mistercade/
rm -r /media/fat/tmp/mistercade/*

# Download mistercade_latest.zip
if [ ! -f /media/fat/tmp/mistercade/MiSTercade_latest.zip ]; then
    echo 'Latest MiSTercade firmware not found, downloading now...'
    cd /media/fat/tmp/mistercade/
    wget -q https://github.com/misteraddons/MiSTercade/raw/main/MiSTercade%20Firmware/MiSTercade_FW.bin

# Unzip mistercade_latest.zip to /tmp/mistercade
# (Back up existing files?)
# Check INI flags
# Copy files from /tmp/mistercade to destination paths

#echo "Would you like to overwrite your existing MiSTer.ini? (y/n)"
#read INI_OVERWRITE

if [ $INI_OVERWRITE==TRUE ]; then
	if [ MONITOR_RESOLUTION_31KHZ==TRUE ]; then
		if [ MONITOR_ORIENTATION==YOKO ]; then
			cp /media/fat/tmp/mistercade/MiSTer-31kHz-YOKO.ini /media/fat/MiSTer.ini
		elif [ MONITOR_ORIENTATION==TATE_CW ]; then
			cp /media/fat/tmp/mistercade/MiSTer-31kHz-TATE_CW.ini /media/fat/MiSTer.ini
		elif [ MONITOR_ORIENTATION==TATE_CCW ]; then
			cp /media/fat/tmp/mistercade/MiSTer-31kHz-TATE_CCW.ini /media/fat/MiSTer.ini
		fi
	elif [ MONITOR_RESOLUTION_15KHZ==TRUE ]; then
		if [ MONITOR_ORIENTATION==YOKO ]; then
			cp /media/fat/tmp/mistercade/MiSTer-15kHz-YOKO.ini /media/fat/MiSTer.ini
		elif [ MONITOR_ORIENTATION==TATE_CW ]; then
			cp /media/fat/tmp/mistercade/MiSTer-15kHz-TATE_CW.ini /media/fat/MiSTer.ini
		elif [ MONITOR_ORIENTATION==TATE_CCW ]; then
			cp /media/fat/tmp/mistercade/MiSTer-15kHz-TATE_CCW.ini /media/fat/MiSTer.ini
		fi
	fi
fi
# Do not overwrite
#	MiSTer.ini once

ORIGINAL_SCRIPT_PATH="$0"
if [ "$ORIGINAL_SCRIPT_PATH" == "bash" ]
then
	ORIGINAL_SCRIPT_PATH=$(ps | grep "^ *$PPID " | grep -o "[^ ]*$")
fi
INI_PATH=${ORIGINAL_SCRIPT_PATH%.*}.ini
if [ -f $INI_PATH ]
then
	eval "$(cat $INI_PATH | tr -d '\r')"
fi

if [ -d "${BASE_PATH}/${OLD_SCRIPTS_PATH}" ] && [ ! -d "${BASE_PATH}/${SCRIPTS_PATH}" ]
then
	mv "${BASE_PATH}/${OLD_SCRIPTS_PATH}" "${BASE_PATH}/${SCRIPTS_PATH}"
	echo "Moved"
	echo "${BASE_PATH}/${OLD_SCRIPTS_PATH}"
	echo "to"
	echo "${BASE_PATH}/${SCRIPTS_PATH}"
	echo "please relaunch the script."
	exit 3
fi

SSL_SECURITY_OPTION=""
curl $CURL_RETRY -q https://github.com &>/dev/null
case $? in
	0)
		;;
	60)
		if [ "$ALLOW_INSECURE_SSL" == "true" ]
		then
			SSL_SECURITY_OPTION="--insecure"
		else
			echo "CA certificates need"
			echo "to be fixed for"
			echo "using SSL certificate"
			echo "verification."
			echo "Please fix them i.e."
			echo "using security_fixes.sh"
			exit 2
		fi
		;;
	*)
		echo "No Internet connection"
		exit 1
		;;
esac
if [ "$SSL_SECURITY_OPTION" == "" ]
then
	if [ "$(cat "$ORIGINAL_SCRIPT_PATH" | grep "^[^#].*")" == "curl $CURL_RETRY -ksLf https://github.com/misteraddons/MiSTercade/blob/main/Scripts/update.sh?raw=true | bash -" ]
	then
		echo "Downloading $(echo $ORIGINAL_SCRIPT_PATH | sed 's/.*\///g')"
		echo ""
		curl $CURL_RETRY $SSL_SECURITY_OPTION -L "https://github.com/misteraddons/MiSTercade/blob/main/Scripts/update.sh?raw=true" -o "$ORIGINAL_SCRIPT_PATH"
	fi
fi

## sync with a public time server
if [[ -n "${NTP_SERVER}" ]] ; then
	echo "Syncing date and time with"
	echo "${NTP_SERVER}"
	# (-b) force time reset, (-s) write output to syslog, (-u) use
	# unprivileged port for outgoing packets to workaround firewalls
	ntpdate -b -s -u "${NTP_SERVER}"
    echo
fi


mkdir -p "${CORE_CATEGORY_PATHS[@]}"

declare -A NEW_CORE_CATEGORY_PATHS
if [ "$DOWNLOAD_NEW_CORES" != "true" ] && [ "$DOWNLOAD_NEW_CORES" != "false" ] && [ "$DOWNLOAD_NEW_CORES" != "" ]
then
	for idx in "${!CORE_CATEGORY_PATHS[@]}"; do
		NEW_CORE_CATEGORY_PATHS[$idx]=$(echo ${CORE_CATEGORY_PATHS[$idx]} | sed "s/$(echo $BASE_PATH | sed 's/\//\\\//g')/$(echo $BASE_PATH | sed 's/\//\\\//g')\/$DOWNLOAD_NEW_CORES/g")
	done
	mkdir -p "${NEW_CORE_CATEGORY_PATHS[@]}"
fi

[ "${UPDATE_LINUX}" == "true" ] && SD_INSTALLER_URL="https://github.com/MiSTer-devel/SD-Installer-Win64_MiSTer"

CORE_URLS=$SD_INSTALLER_URL$'\n'$MISTER_URL$'\n'$(curl $CURL_RETRY $SSL_SECURITY_OPTION -sLf "$MISTER_URL/wiki"| awk '/(user-content-cores)|(user-content-computer-cores)/,/user-content-development/' | grep -io '\(https://github.com/[a-zA-Z0-9./_-]*_MiSTer\)\|\(user-content-[a-z-]*\)')
CORE_CATEGORY="-"
SD_INSTALLER_PATH=""
REBOOT_NEEDED="false"
CORE_CATEGORIES_FILTER=""
if [ "$REPOSITORIES_FILTER" != "" ]
then
	CORE_CATEGORIES_FILTER="^\($( echo "$REPOSITORIES_FILTER" | sed 's/[ 	]\{1,\}/\\)\\|\\(/g' )\)$"
	REPOSITORIES_FILTER="\(Main_MiSTer\)\|\(Menu_MiSTer\)\|\(SD-Installer-Win64_MiSTer\)\|\($( echo "$REPOSITORIES_FILTER" | sed 's/[ 	]\{1,\}/\\)\\|\\([\/_-]/g' )\)"
fi

GOOD_CORES=""
if [ "$GOOD_CORES_URL" != "" ]
then
	GOOD_CORES=$(curl $CURL_RETRY $SSL_SECURITY_OPTION -sLf "$GOOD_CORES_URL")
fi


if [ "${UPDATE_CHEATS}" != "false" ]
then
	echo "Checking Cheats"
	echo ""
	CHEAT_URLS=$(curl $CURL_RETRY $SSL_SECURITY_OPTION -sLf --cookie "challenge=BitMitigate.com" "${CHEATS_URL}" | grep -oE '"mister_[^_]+_[0-9]{8}.zip"' | sed 's/"//g')
	for CHEAT_MAPPING in ${CHEAT_MAPPINGS}; do
		[ "$PARALLEL_UPDATE" == "true" ] && { echo "$(checkCheat)"$'\n' & } || checkCheat
	done
	wait
fi

echo "Done!"

exit 0
