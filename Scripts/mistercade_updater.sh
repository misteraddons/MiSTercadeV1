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
	if [ "$(cat "$ORIGINAL_SCRIPT_PATH" | grep "^[^#].*")" == "curl $CURL_RETRY -ksLf https://github.com/MiSTer-devel/Updater_script_MiSTer/blob/master/mister_updater.sh?raw=true | bash -" ]
	then
		echo "Downloading $(echo $ORIGINAL_SCRIPT_PATH | sed 's/.*\///g')"
		echo ""
		curl $CURL_RETRY $SSL_SECURITY_OPTION -L "https://github.com/MiSTer-devel/Updater_script_MiSTer/blob/master/update.sh?raw=true" -o "$ORIGINAL_SCRIPT_PATH"
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

function checkCoreURL {
	echo "Checking $(echo $CORE_URL | sed 's/.*\///g' | sed 's/_MiSTer//gI')"
	[ "${SSH_CLIENT}" != "" ] && echo "URL: $CORE_URL"
	if echo "$CORE_URL" | grep -q "SD-Installer"
	then
		RELEASES_URL="$CORE_URL"
	else
		RELEASES_URL=https://github.com$(curl $CURL_RETRY $SSL_SECURITY_OPTION -sLf "$CORE_URL" | grep -o '/MiSTer-devel/[a-zA-Z0-9./_-]*/tree/[a-zA-Z0-9./_-]*/releases' | head -n1)
	fi
	RELEASE_URLS=$(curl $CURL_RETRY $SSL_SECURITY_OPTION -sLf "$RELEASES_URL" | grep -o '/MiSTer-devel/[a-zA-Z0-9./_-]*_[0-9]\{8\}[a-zA-Z]\?\(\.rbf\|\.rar\)\?')
	
	MAX_VERSION=""
	MAX_RELEASE_URL=""
	GOOD_CORE_VERSION=""
	for RELEASE_URL in $RELEASE_URLS; do
		if echo "$RELEASE_URL" | grep -q "SharpMZ"
		then
			RELEASE_URL=$(echo "$RELEASE_URL"  | grep '\.rbf$')
		fi			
		if echo "$RELEASE_URL" | grep -q "Atari800"
		then
			if [ "$CORE_CATEGORY" == "cores" ]
			then
				RELEASE_URL=$(echo "$RELEASE_URL"  | grep '800_[0-9]\{8\}[a-zA-Z]\?\.rbf$')
			else
				RELEASE_URL=$(echo "$RELEASE_URL"  | grep '5200_[0-9]\{8\}[a-zA-Z]\?\.rbf$')
			fi
		fi			
		CURRENT_VERSION=$(echo "$RELEASE_URL" | grep -o '[0-9]\{8\}[a-zA-Z]\?')
		
		if [ "$GOOD_CORES" != "" ]
		then
			GOOD_CORE_VERSION=$(echo "$GOOD_CORES" | grep -wo "$(echo "$RELEASE_URL" | sed 's/.*\///g')" | grep -o '[0-9]\{8\}[a-zA-Z]\?')
			if [ "$GOOD_CORE_VERSION" != "" ]
			then
				MAX_VERSION=$CURRENT_VERSION
				MAX_RELEASE_URL=$RELEASE_URL
				break
			fi
		fi
		
		if [[ "$CURRENT_VERSION" > "$MAX_VERSION" ]]
		then
			MAX_VERSION=$CURRENT_VERSION
			MAX_RELEASE_URL=$RELEASE_URL
		fi
	done
	
	FILE_NAME=$(echo "$MAX_RELEASE_URL" | sed 's/.*\///g')
	if [ "$CORE_CATEGORY" == "arcade-cores" ] && [ $REMOVE_ARCADE_PREFIX == "true" ]
	then
		FILE_NAME=$(echo "$FILE_NAME" | sed 's/Arcade-//gI')
	fi
	BASE_FILE_NAME=$(echo "$FILE_NAME" | sed 's/_[0-9]\{8\}.*//g')
	
	CURRENT_DIRS="${CORE_CATEGORY_PATHS[$CORE_CATEGORY]}"
	if [ "${NEW_CORE_CATEGORY_PATHS[$CORE_CATEGORY]}" != "" ]
	then
		CURRENT_DIRS=("$CURRENT_DIRS" "${NEW_CORE_CATEGORY_PATHS[$CORE_CATEGORY]}")
	fi 
	if [ "$CURRENT_DIRS" == "" ]
	then
		CURRENT_DIRS=("$BASE_PATH")
	fi
	if [ "$BASE_FILE_NAME" == "MiSTer" ] || [ "$BASE_FILE_NAME" == "menu" ] || { echo "$CORE_URL" | grep -q "SD-Installer"; }
	then
		mkdir -p "$WORK_PATH"
		CURRENT_DIRS=("$WORK_PATH")
	fi
	
	CURRENT_LOCAL_VERSION=""
	MAX_LOCAL_VERSION=""
	for CURRENT_DIR in "${CURRENT_DIRS[@]}"
	do
		for CURRENT_FILE in "$CURRENT_DIR/$BASE_FILE_NAME"*
		do
			if [ -f "$CURRENT_FILE" ]
			then
				if echo "$CURRENT_FILE" | grep -q "$BASE_FILE_NAME\_[0-9]\{8\}[a-zA-Z]\?\(\.rbf\|\.rar\)\?$"
				then
					CURRENT_LOCAL_VERSION=$(echo "$CURRENT_FILE" | grep -o '[0-9]\{8\}[a-zA-Z]\?')
					if [ "$GOOD_CORE_VERSION" != "" ]
					then
						if [ "$CURRENT_LOCAL_VERSION" == "$GOOD_CORE_VERSION" ]
						then
							MAX_LOCAL_VERSION=$CURRENT_LOCAL_VERSION
						else
							if [ "$MAX_LOCAL_VERSION" == "" ]
							then
								MAX_LOCAL_VERSION="00000000"
							fi
							if [ $DELETE_OLD_FILES == "true" ]
							then
								mv "${CURRENT_FILE}" "${CURRENT_FILE}.${TO_BE_DELETED_EXTENSION}" > /dev/null 2>&1
							fi
						fi
					else
						if [[ "$CURRENT_LOCAL_VERSION" > "$MAX_LOCAL_VERSION" ]]
						then
							MAX_LOCAL_VERSION=$CURRENT_LOCAL_VERSION
						fi
						if [[ "$MAX_VERSION" > "$CURRENT_LOCAL_VERSION" ]] && [ $DELETE_OLD_FILES == "true" ]
						then
							# echo "Moving $(echo ${CURRENT_FILE} | sed 's/.*\///g')"
							mv "${CURRENT_FILE}" "${CURRENT_FILE}.${TO_BE_DELETED_EXTENSION}" > /dev/null 2>&1
						fi
					fi
				
				fi
			fi
		done
		if [ "$MAX_LOCAL_VERSION" != "" ]
		then
			break
		fi
	done
	
	if [ "${BASE_FILE_NAME}" == "MiSTer" ] || [ "${BASE_FILE_NAME}" == "menu" ]
	then
		if [[ "${MAX_VERSION}" == "${MAX_LOCAL_VERSION}" ]]
		then
			DESTINATION_FILE=$(echo "${MAX_RELEASE_URL}" | sed 's/.*\///g' | sed 's/_[0-9]\{8\}[a-zA-Z]\{0,1\}//g')
			ACTUAL_CRC=$(md5sum "/media/fat/${DESTINATION_FILE}" | grep -o "^[^ ]*")
			SAVED_CRC=$(cat "${WORK_PATH}/${FILE_NAME}")
			if [ "$ACTUAL_CRC" != "$SAVED_CRC" ]
			then
				mv "${CURRENT_FILE}" "${CURRENT_FILE}.${TO_BE_DELETED_EXTENSION}" > /dev/null 2>&1
				MAX_LOCAL_VERSION=""
			fi
		fi
	fi
	
	if [[ "$MAX_VERSION" > "$MAX_LOCAL_VERSION" ]]
	then
		if [ "$DOWNLOAD_NEW_CORES" != "false" ] || [ "$MAX_LOCAL_VERSION" != "" ] || [ "$BASE_FILE_NAME" == "MiSTer" ] || [ "$BASE_FILE_NAME" == "menu" ] || { echo "$CORE_URL" | grep -q "SD-Installer"; }
		then
			echo "Downloading $FILE_NAME"
			[ "${SSH_CLIENT}" != "" ] && echo "URL: https://github.com$MAX_RELEASE_URL?raw=true"
			if curl $CURL_RETRY $SSL_SECURITY_OPTION -L "https://github.com$MAX_RELEASE_URL?raw=true" -o "$CURRENT_DIR/$FILE_NAME"
			then
				if [ ${DELETE_OLD_FILES} == "true" ]
				then
					echo "Deleting old ${BASE_FILE_NAME} files"
					rm "${CURRENT_DIR}/${BASE_FILE_NAME}"*.${TO_BE_DELETED_EXTENSION} > /dev/null 2>&1
				fi
				if [ $BASE_FILE_NAME == "MiSTer" ] || [ $BASE_FILE_NAME == "menu" ]
				then
					DESTINATION_FILE=$(echo "$MAX_RELEASE_URL" | sed 's/.*\///g' | sed 's/_[0-9]\{8\}[a-zA-Z]\{0,1\}//g')
					echo "Moving $DESTINATION_FILE"
					rm "/media/fat/$DESTINATION_FILE" > /dev/null 2>&1
					mv "$CURRENT_DIR/$FILE_NAME" "/media/fat/$DESTINATION_FILE"
					echo "$(md5sum "/media/fat/${DESTINATION_FILE}" | grep -o "^[^ ]*")" > "${CURRENT_DIR}/${FILE_NAME}"
					REBOOT_NEEDED="true"
				fi
				if echo "$CORE_URL" | grep -q "SD-Installer"
				then
					SD_INSTALLER_PATH="$CURRENT_DIR/$FILE_NAME"
				fi
				if [ "$CORE_CATEGORY" == "arcade-cores" ]
				then
					OLD_IFS="$IFS"
					IFS="|"
					for ARCADE_ALT_PATH in $ARCADE_ALT_PATHS
					do
						for ARCADE_ALT_DIR in "$ARCADE_ALT_PATH/_$BASE_FILE_NAME"*
						do
							if [ -d "$ARCADE_ALT_DIR" ]
							then
								echo "Updating $(echo $ARCADE_ALT_DIR | sed 's/.*\///g')"
								if [ $DELETE_OLD_FILES == "true" ]
								then
									for ARCADE_HACK_CORE in "$ARCADE_ALT_DIR/"*.rbf
									do
										if [ -f "$ARCADE_HACK_CORE" ] && { echo "$ARCADE_HACK_CORE" | grep -q "$BASE_FILE_NAME\_[0-9]\{8\}[a-zA-Z]\?\.rbf$"; }
										then
											rm "$ARCADE_HACK_CORE"  > /dev/null 2>&1
										fi
									done
								fi
								cp "$CURRENT_DIR/$FILE_NAME" "$ARCADE_ALT_DIR/"
							fi
						done
					done
					IFS="$OLD_IFS"
				fi
				if [ "$CREATE_CORES_DIRECTORIES" != "false" ] && [ "$MAX_LOCAL_VERSION" == "" ]
				then
					if [ "$BASE_FILE_NAME" != "menu" ] && [ "$CORE_CATEGORY" == "cores" ] || [ "$CORE_CATEGORY" == "computer-cores" ] || [ "$CORE_CATEGORY" == "console-cores" ]
					then
						CORE_SOURCE_URL=""
						CORE_INTERNAL_NAME=""
						case "${BASE_FILE_NAME}" in
							"Minimig")
								CORE_INTERNAL_NAME="Amiga"
								;;
							"Apple-I"|"C64"|"PDP1"|"NeoGeo")
								CORE_INTERNAL_NAME="${BASE_FILE_NAME}"
								;;
							"SharpMZ")
								CORE_INTERNAL_NAME="SHARP MZ SERIES"
								;;
							*)
								CORE_SOURCE_URL="$(echo "https://github.com$MAX_RELEASE_URL" | sed 's/releases.*//g')${BASE_FILE_NAME}.sv"
								CORE_INTERNAL_NAME="$(curl $CURL_RETRY $SSL_SECURITY_OPTION -sLf "${CORE_SOURCE_URL}?raw=true" | awk '/CONF_STR[^=]*=/,/;/' | grep -oE -m1 '".*?;' | sed 's/[";]//g')"
								;;
						esac
						if [ "$CORE_INTERNAL_NAME" != "" ]
						then
							echo "Creating $BASE_PATH/$CORE_INTERNAL_NAME directory"
							mkdir -p "$BASE_PATH/$CORE_INTERNAL_NAME"
						fi
					fi
				fi
			else
				echo "${FILE_NAME} download failed"
				rm "${CURRENT_DIR}/${FILE_NAME}" > /dev/null 2>&1
				if [ ${DELETE_OLD_FILES} == "true" ]
				then
					echo "Restoring old ${BASE_FILE_NAME} files"
					for FILE_TO_BE_RESTORED in "${CURRENT_DIR}/${BASE_FILE_NAME}"*.${TO_BE_DELETED_EXTENSION}
					do
					  mv "${FILE_TO_BE_RESTORED}" "${FILE_TO_BE_RESTORED%.${TO_BE_DELETED_EXTENSION}}" > /dev/null 2>&1
					done
				fi
			fi
			sync
		else
			echo "New core: $FILE_NAME"
		fi
	else
		echo "Nothing to update"
	fi
	
	echo ""
}

for CORE_URL in $CORE_URLS; do
	if [[ $CORE_URL == https://* ]]
	then
		if [ "$REPOSITORIES_FILTER" == "" ] || { echo "$CORE_URL" | grep -qi "$REPOSITORIES_FILTER";  } || { echo "$CORE_CATEGORY" | grep -qi "$CORE_CATEGORIES_FILTER";  }
		then
			if echo "$CORE_URL" | grep -qE "(SD-Installer)|(/Main_MiSTer$)|(/Menu_MiSTer$)"
			then
				checkCoreURL
			else
				[ "$PARALLEL_UPDATE" == "true" ] && { echo "$(checkCoreURL)"$'\n' & } || checkCoreURL
			fi
		fi
	else
		CORE_CATEGORY=$(echo "$CORE_URL" | sed 's/user-content-//g')
		if [ "$CORE_CATEGORY" == "" ]
		then
			CORE_CATEGORY="-"
		fi
		if [ "$CORE_CATEGORY" == "computer-cores" ]
		then
			CORE_CATEGORY="cores"
		fi
	fi
done
wait

function checkAdditionalRepository {
	OLD_IFS="$IFS"
	IFS="|"
	PARAMS=($ADDITIONAL_REPOSITORY)
	ADDITIONAL_FILES_URL="${PARAMS[0]}"
	ADDITIONAL_FILES_EXTENSIONS="\($(echo ${PARAMS[1]} | sed 's/ \{1,\}/\\|/g')\)"
	CURRENT_DIR="${PARAMS[2]}"
	IFS="$OLD_IFS"
	if [ ! -d "$CURRENT_DIR" ]
	then
		mkdir -p "$CURRENT_DIR"
	fi
	echo "Checking $(echo $ADDITIONAL_FILES_URL | sed 's/.*\///g' | awk '{ print toupper( substr( $0, 1, 1 ) ) substr( $0, 2 ); }')"
	[ "${SSH_CLIENT}" != "" ] && echo "URL: $ADDITIONAL_FILES_URL"
	if echo "$ADDITIONAL_FILES_URL" | grep -q "\/tree\/master\/"
	then
		ADDITIONAL_FILES_URL=$(echo "$ADDITIONAL_FILES_URL" | sed 's/\/tree\/master\//\/file-list\/master\//g')
	else
		ADDITIONAL_FILES_URL="$ADDITIONAL_FILES_URL/file-list/master"
	fi
	CONTENT_TDS=$(curl $CURL_RETRY $SSL_SECURITY_OPTION -sLf "$ADDITIONAL_FILES_URL")
	ADDITIONAL_FILE_DATETIMES=$(echo "$CONTENT_TDS" | awk '/class="age">/,/<\/td>/' | tr -d '\n' | sed 's/ \{1,\}/+/g' | sed 's/<\/td>/\n/g')
	ADDITIONAL_FILE_DATETIMES=( $ADDITIONAL_FILE_DATETIMES )
	for DATETIME_INDEX in "${!ADDITIONAL_FILE_DATETIMES[@]}"; do 
		ADDITIONAL_FILE_DATETIMES[$DATETIME_INDEX]=$(echo "${ADDITIONAL_FILE_DATETIMES[$DATETIME_INDEX]}" | grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}Z" )
		if [ "${ADDITIONAL_FILE_DATETIMES[$DATETIME_INDEX]}" == "" ]
		then
			ADDITIONAL_FILE_DATETIMES[$DATETIME_INDEX]="${ADDITIONAL_FILE_DATETIMES[$((DATETIME_INDEX-1))]}"
		fi
	done
	CONTENT_TDS=$(echo "$CONTENT_TDS" | awk '/class="content">/,/<\/td>/' | tr -d '\n' | sed 's/ \{1,\}/+/g' | sed 's/<\/td>/\n/g')
	CONTENT_TD_INDEX=0
	for CONTENT_TD in $CONTENT_TDS; do
		ADDITIONAL_FILE_URL=$(echo "$CONTENT_TD" | grep -o "href=\(\"\|\'\)[a-zA-Z0-9%()./_-]*\.$ADDITIONAL_FILES_EXTENSIONS\(\"\|\'\)" | sed "s/href=//g" | sed "s/\(\"\|\'\)//g")
		if [ "$ADDITIONAL_FILE_URL" != "" ]
		then
			ADDITIONAL_FILE_NAME=$(echo "$ADDITIONAL_FILE_URL" | sed 's/.*\///g' | sed 's/%20/ /g')
			ADDITIONAL_ONLINE_FILE_DATETIME=${ADDITIONAL_FILE_DATETIMES[$CONTENT_TD_INDEX]}
			if [ -f "$CURRENT_DIR/$ADDITIONAL_FILE_NAME" ]
			then
				ADDITIONAL_LOCAL_FILE_DATETIME=$(date -d "$(stat -c %y "$CURRENT_DIR/$ADDITIONAL_FILE_NAME" 2>/dev/null)" -u +"%Y-%m-%dT%H:%M:%SZ")
			else
				ADDITIONAL_LOCAL_FILE_DATETIME=""
			fi
			if [ "$ADDITIONAL_LOCAL_FILE_DATETIME" == "" ] || [[ "$ADDITIONAL_ONLINE_FILE_DATETIME" > "$ADDITIONAL_LOCAL_FILE_DATETIME" ]]
			then
				echo "Downloading $ADDITIONAL_FILE_NAME"
				[ "${SSH_CLIENT}" != "" ] && echo "URL: https://github.com$ADDITIONAL_FILE_URL?raw=true"
				mv "${CURRENT_DIR}/${ADDITIONAL_FILE_NAME}" "${CURRENT_DIR}/${ADDITIONAL_FILE_NAME}.${TO_BE_DELETED_EXTENSION}" > /dev/null 2>&1
				if curl $CURL_RETRY $SSL_SECURITY_OPTION -L "https://github.com$ADDITIONAL_FILE_URL?raw=true" -o "$CURRENT_DIR/$ADDITIONAL_FILE_NAME"
				then
					rm "${CURRENT_DIR}/${ADDITIONAL_FILE_NAME}.${TO_BE_DELETED_EXTENSION}" > /dev/null 2>&1
				else
					echo "${ADDITIONAL_FILE_NAME} download failed"
					echo "Restoring old ${ADDITIONAL_FILE_NAME} file"
					rm "${CURRENT_DIR}/${ADDITIONAL_FILE_NAME}" > /dev/null 2>&1
					mv "${CURRENT_DIR}/${ADDITIONAL_FILE_NAME}.${TO_BE_DELETED_EXTENSION}" "${CURRENT_DIR}/${ADDITIONAL_FILE_NAME}" > /dev/null 2>&1
				fi
				sync
				echo ""
			fi
		fi
		CONTENT_TD_INDEX=$((CONTENT_TD_INDEX+1))
	done
	echo ""
}

for ADDITIONAL_REPOSITORY in "${ADDITIONAL_REPOSITORIES[@]}"; do
	[ "$PARALLEL_UPDATE" == "true" ] && { echo "$(checkAdditionalRepository)"$'\n' & } || checkAdditionalRepository
done
wait

function checkCheat {
	MAPPING_KEY=$(echo "${CHEAT_MAPPING}" | grep -o "^[^:]*")
	MAPPING_VALUE=$(echo "${CHEAT_MAPPING}" | grep -o "[^:]*$")
	MAX_VERSION=""
	FILE_NAME=$(echo "${CHEAT_URLS}" | grep "mister_${MAPPING_KEY}_")
	echo "Checking ${MAPPING_KEY^^}"
	if [ "${FILE_NAME}" != "" ]
	then
		CHEAT_URL="${CHEATS_URL}${FILE_NAME}"
		MAX_VERSION=$(echo "${FILE_NAME}" | grep -oE "[0-9]{8}")
		CURRENT_LOCAL_VERSION=""
		MAX_LOCAL_VERSION=""
		for CURRENT_FILE in "${WORK_PATH}/mister_${MAPPING_KEY}_"*
		do
			if [ -f "${CURRENT_FILE}" ]
			then
				if echo "${CURRENT_FILE}" | grep -qE "mister_[^_]+_[0-9]{8}.zip"
				then
					CURRENT_LOCAL_VERSION=$(echo "${CURRENT_FILE}" | grep -oE '[0-9]{8}')
					[ "${UPDATE_CHEATS}" == "once" ] && CURRENT_LOCAL_VERSION="99999999"
					if [[ "${CURRENT_LOCAL_VERSION}" > "${MAX_LOCAL_VERSION}" ]]
					then
						MAX_LOCAL_VERSION=${CURRENT_LOCAL_VERSION}
					fi
					if [[ "${MAX_VERSION}" > "${CURRENT_LOCAL_VERSION}" ]] && [ "${DELETE_OLD_FILES}" == "true" ]
					then
						mv "${CURRENT_FILE}" "${CURRENT_FILE}.${TO_BE_DELETED_EXTENSION}" > /dev/null 2>&1
					fi
				fi
			fi
		done
		if [[ "${MAX_VERSION}" > "${MAX_LOCAL_VERSION}" ]]
		then
			echo "Downloading ${FILE_NAME}"
			[ "${SSH_CLIENT}" != "" ] && echo "URL: ${CHEAT_URL}"
			if curl $CURL_RETRY $SSL_SECURITY_OPTION -L --cookie "challenge=BitMitigate.com" "${CHEAT_URL}" -o "${WORK_PATH}/${FILE_NAME}"
			then
				if [ ${DELETE_OLD_FILES} == "true" ]
				then
					echo "Deleting old mister_${MAPPING_KEY} files"
					rm "${WORK_PATH}/mister_${MAPPING_KEY}_"*.${TO_BE_DELETED_EXTENSION} > /dev/null 2>&1
				fi
				mkdir -p "${BASE_PATH}/cheats/${MAPPING_VALUE}"
				sync
				echo "Extracting ${FILE_NAME}"
				unzip -o "${WORK_PATH}/${FILE_NAME}" -d "${BASE_PATH}/cheats/${MAPPING_VALUE}" 1>&2
				rm "${WORK_PATH}/${FILE_NAME}" > /dev/null 2>&1
				touch "${WORK_PATH}/${FILE_NAME}" > /dev/null 2>&1
			else
				echo "${FILE_NAME} download failed"
				rm "${WORK_PATH}/${FILE_NAME}" > /dev/null 2>&1
				if [ ${DELETE_OLD_FILES} == "true" ]
				then
					echo "Restoring old mister_${MAPPING_KEY} files"
					for FILE_TO_BE_RESTORED in "${WORK_PATH}/mister_${MAPPING_KEY}_"*.${TO_BE_DELETED_EXTENSION}
					do
					  mv "${FILE_TO_BE_RESTORED}" "${FILE_TO_BE_RESTORED%.${TO_BE_DELETED_EXTENSION}}" > /dev/null 2>&1
					done
				fi
			fi
			sync
		fi
	fi
	echo ""
}

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

if [ "$SD_INSTALLER_PATH" != "" ]
then
	echo "Linux system must be updated"
	if [ ! -f "/media/fat/linux/unrar-nonfree" ]
	then
		UNRAR_DEB_URLS=$(curl $CURL_RETRY $SSL_SECURITY_OPTION -sLf "$UNRAR_DEBS_URL" | grep -o '\"unrar[a-zA-Z0-9%./_+-]*_armhf\.deb\"' | sed 's/\"//g')
		MAX_VERSION=""
		MAX_RELEASE_URL=""
		for RELEASE_URL in $UNRAR_DEB_URLS; do
			CURRENT_VERSION=$(echo "$RELEASE_URL" | grep -o '_[a-zA-Z0-9.+-]*_' | sed 's/_//g')
			if [[ "$CURRENT_VERSION" > "$MAX_VERSION" ]]
			then
				MAX_VERSION=$CURRENT_VERSION
				MAX_RELEASE_URL=$RELEASE_URL
			fi
		done
		echo "Downloading $UNRAR_DEBS_URL/$MAX_RELEASE_URL"
		curl $SSL_SECURITY_OPTION -L "$UNRAR_DEBS_URL/$MAX_RELEASE_URL" -o "$TEMP_PATH/$MAX_RELEASE_URL"
		echo "Extracting unrar-nonfree"
		ORIGINAL_DIR=$(pwd)
		cd "$TEMP_PATH"
		rm data.tar.xz > /dev/null 2>&1
		ar -x "$TEMP_PATH/$MAX_RELEASE_URL" data.tar.xz
		cd "$ORIGINAL_DIR"
		rm "$TEMP_PATH/$MAX_RELEASE_URL"
		tar -xJf "$TEMP_PATH/data.tar.xz" --strip-components=3 -C "/media/fat/linux" ./usr/bin/unrar-nonfree
		rm "$TEMP_PATH/data.tar.xz" > /dev/null 2>&1
	fi
	if [ -f "/media/fat/linux/unrar-nonfree" ] && [ -f "$SD_INSTALLER_PATH" ]
	then
		sync
		if /media/fat/linux/unrar-nonfree t "$SD_INSTALLER_PATH"
		then
			if [ -d /media/fat/linux.update ]
			then
				rm -R "/media/fat/linux.update" > /dev/null 2>&1
			fi
			mkdir "/media/fat/linux.update"
			if /media/fat/linux/unrar-nonfree x -y "$SD_INSTALLER_PATH" files/linux/* /media/fat/linux.update
			then
				echo ""
				echo "======================================================================================"
				echo "Hold your breath: updating the Kernel, the Linux filesystem, the bootloader and stuff."
				echo "Stopping this will make your SD unbootable!"
				echo ""
				echo "If something goes wrong, please download the SD Installer from"
				echo "$SD_INSTALLER_URL"
				echo "and copy the content of the files/linux/ directory in the linux directory of the SD."
				echo "Reflash the bootloader with the SD Installer if needed."
				echo "======================================================================================"
				echo ""
				rm "$SD_INSTALLER_PATH" > /dev/null 2>&1
				touch "$SD_INSTALLER_PATH"
				sync
				mv -f "/media/fat/linux.update/files/linux/linux.img" "/media/fat/linux/linux.img.new"
				mv -f "/media/fat/linux.update/files/linux/"* "/media/fat/linux/"
				rm -R "/media/fat/linux.update" > /dev/null 2>&1
				sync
				/media/fat/linux/updateboot
				sync
				mv -f "/media/fat/linux/linux.img.new" "/media/fat/linux/linux.img"
				sync
			else
				rm -R "/media/fat/linux.update" > /dev/null 2>&1
				sync
			fi
			REBOOT_NEEDED="true"
		else
			echo "Downloaded installer RAR is broken, deleting $SD_INSTALLER_PATH"
			rm "$SD_INSTALLER_PATH" > /dev/null 2>&1
		fi
	fi
fi

echo "Done!"
if [ $REBOOT_NEEDED == "true" ]
then
	if [ $AUTOREBOOT == "true" ]
	then
		echo "Rebooting in $REBOOT_PAUSE seconds"
		sleep $REBOOT_PAUSE
		reboot now
	else
		echo "You should reboot"
	fi
fi

exit 0
