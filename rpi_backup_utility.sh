#!/bin/bash

SYSTEM="/dev/mmcblk0"
HARD_DRIVE_TEMP="/etc/rpu/ARG0-HDSWAP.bin"
BACKUP_DIR="/mnt/mass/"
BACKUP_COUNT=5
EXPECTED_COUNT=2

# ANSI COLORS
YELLOW='\e[33m'
GREEN='\e[32m'
WHITE='\e[1;37m'
RED='\e[1;31m'
CYAN='\e[1;36m'
RESET='\e[0m'


checkHARD_DRIVE() {
    if [ ! -d "$(dirname "$HARD_DRIVE_TEMP")" ]; then
        sudo mkdir -p "$(dirname "$HARD_DRIVE_TEMP")"
    fi

    if [ -f "$HARD_DRIVE_TEMP" ]; then
        HARD_DRIVE=$(cat "$HARD_DRIVE_TEMP")
        if ! mount | grep -q "$HARD_DRIVE" && lsblk -o NAME | grep -q "$HARD_DRIVE"; then
            listDevices
            echo "${YELLOW}${HARD_DRIVE} DEVICE DISCONNECTED${RESET}"
            promptForDrive
        fi
    else
        listDevices
        promptForDrive
    fi
}

listDevices() {
    echo ""
    lsblk --output NAME,TYPE | awk '
    NR == 1 {print $0}
    NR > 1 {
        if ($2 == "part") {
            printf "\033[1;32m%s\033[0m\n", $0;
        } else if ($1 ~ /^(sda|sdb|sdc)$/) {
            printf "\033[1;33m%s\033[0m\n", $0;
        } else if ($1 ~ /^nvme/) {
            printf "\033[1;35m%s\033[0m\n", $0;
        } else {
            printf "\033[2m%s\033[0m\n", $0;
        }
    }'
    echo ""
}

promptForDrive() {
    echo "${WHITE}ENTER HARD DRIVE MOUNT POINT: ${CYAN}(ex: /dev/sda1):${RESET} "
    read INPUT_DRIVE
    HARD_DRIVE=$(echo "$INPUT_DRIVE" | sed 's:/*$::')
    echo "$HARD_DRIVE" > "$HARD_DRIVE_TEMP"
    mountFunction
}

checkImages() {
    echo ""
    cd "$BACKUP_DIR" || exit

    FILE_COUNT=$(ls -t | wc -l)
    if [ "$FILE_COUNT" -gt "$BACKUP_COUNT" ]; then
        FILES_TO_DEL=$(ls -t | tail -n +"$EXPECTED_COUNT")
        for FILE in $FILES_TO_DEL; do
            echo "${WHITE}$FILE ${GREEN}~ ${RED}OLD BACKUP FILE HAS BEEN REMOVED FROM ${CYAN}$BACKUP_DIR${RESET}"
            rm -f "$FILE"
        done
    fi
}

createImage() {
    YYYY=$(date +%Y)
    MM=$(date +%m)
    DD=$(date +%d)
    COUNT=0

    IMAGE_NAME="F${COUNT}-RASP-ARG0-${YYYY}-${MM}-${DD}.img.gz"

    while [ -e "${BACKUP_DIR}${IMAGE_NAME}" ]; do
        COUNT=$((COUNT + 1))
        IMAGE_NAME="F${COUNT}-RASP-ARG0-${YYYY}-${MM}-${DD}.img.gz"
    done

    echo ""
    echo "-------------------------------------------------------------"
    echo "${WHITE}Raspberry Pi Backup Utility ${GREEN}~ ${WHITE}https://barisalbayrak.net/${RESET}"
    echo "-------------------------------------------------------------"
    dd if=$SYSTEM bs=128K status=progress | gzip > ${BACKUP_DIR}${IMAGE_NAME}

    latestImage
}

ejectHARD_DRIVE() {
    echo ""
    umount -l "$HARD_DRIVE"
}

startBackup() {
    clear
    echo "${GREEN}⠀⢀⣠⣤⣶⣶⣶⣤⣄⠀⠀⣀⣤⣶⣶⣶⣤⣄⡀⠀
⠀⢸⣿⠁⠀⠀⠀⠀⠙⢷⡾⠋⠀⠀⠀⠀⠈⣿⡇⠀
⠀⠘⢿⡆⠀⠀⠀⠢⣄⣼⣧⣠⠔⠀⠀⠀⢰⡿⠃⠀
⠀⠀⠈⠻⣧⣤⣀⣤⣾⣿⣿⣷⣤⣀⣤⣼⠟⠁⠀⠀${RED}
⠀⠀⣰⡾⠋⠉⣩⣟⠁⠀⠀⠈⣻⣍⠉⠙⢷⣆⠀⠀
⠀⢀⣿⣀⣤⡾⠛⠛⠷⣶⣶⠾⠛⠛⢷⣤⣀⣿⡀⠀
⣰⡟⠉⣿⡏⠀⠀⠀⠀⢹⡏⠀⠀⠀⠀⢹⣿⠉⢻⣆
⣿⡇⠀⣿⣇⠀⠀⠀⣠⣿⣿⣄⠀⠀⠀⣸⣿⠀⢸⣿
⠙⣷⣼⠟⠻⣿⣿⡿⠋⠁⠈⠙⢿⣿⣿⠟⠻⣧⣾⠋
⠀⢸⣿⠀⠀⠈⢿⡇⠀⠀⠀⠀⢸⡿⠁⠀⠀⣿⡇⠀
⠀⠀⠻⣧⣀⣀⣸⣿⣶⣤⣤⣶⣿⣇⣀⣀⣼⠟⠀⠀
⠀⠀⠀⠈⠛⢿⣿⣿⡀⠀⠀⢀⣿⣿⡿⠛⠁⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠙⠻⠿⠿⠟⠋⠀⠀⠀⠀⠀⠀⠀${RESET}
"
    echo "${WHITE}Starting backup process on ${GREEN}~ ${CYAN}$HARD_DRIVE${RESET}"
    echo "${WHITE}This process can take up to several hours depending on the system size."
    echo "${RED}DON'T WRITE ANY DATA TO THE SYSTEM AND DON'T PULL OFF BACKUP STORAGE DURING THIS TIME!${RESET}"
    if [ -d "$BACKUP_DIR" ]; then
        checkImages
    fi

    createImage
    sleep 3
}

latestImage() {
    clear
    cd "$BACKUP_DIR" || exit
    FILENAME=$(ls -t | head -n1)
    FILESIZE=$(stat -c %s "$FILENAME" 2>/dev/null)
    FILE_MODIFICATION_DATE=$(stat -c %y "$FILENAME" 2>/dev/null)
    FILESIZE_MB=$(echo "scale=2; $FILESIZE / (1024*1024)" | bc 2>/dev/null)
    NEW_DATE=$(date -d "$FILE_MODIFICATION_DATE" "+%Y-%m-%d %H:%M")

    if [ -z "$FILESIZE_MB" ]; then
        echo "${CYAN}LATEST BACKUP FILE:\n${WHITE}File: ${RED}NO FILE  ${WHITE}| Size: ${RED}0 MB ${WHITE}|"
    else
        echo "${CYAN}LATEST BACKUP FILE:\n${WHITE}File: ${GREEN}$FILENAME ${WHITE}| Size: ${GREEN}$FILESIZE_MB MB ${WHITE}| Modification Date: ${GREEN}$NEW_DATE${RESET}"
    fi

    ejectHARD_DRIVE
}

mountFunction() {
    if mountpoint -q "$BACKUP_DIR"; then
        echo "${CYAN}$HARD_DRIVE${RESET} ${WHITE}already mounted on >>> ${YELLOW}$BACKUP_DIR${RESET}";
        startBackup
    else
        echo "mounting ${CYAN}$HARD_DRIVE${RESET}\n${RED}DON'T PULL OFF YOUR STORAGE DEVICE...${RESET}";
        mount "$HARD_DRIVE" "$BACKUP_DIR" 2>/dev/null
        sleep 3
        echo "${CYAN}$HARD_DRIVE${RESET} ${WHITE}mounted on >>> ${YELLOW}$BACKUP_DIR${RESET}";
        startBackup
    fi
}

if [ -f "$HARD_DRIVE_TEMP" ]; then
    HARD_DRIVE=$(cat "$HARD_DRIVE_TEMP")
fi

if [ -d "$BACKUP_DIR" ]; then
    mountFunction
    sleep 2
elif [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR" >/dev/null 2>&1
    if [ -f "$HARD_DRIVE_TEMP" ]; then
        echo "${GREEN}BACKUP DIRECTORY CREATED${RESET}"
        sleep 2
        mountFunction
    else
        echo "${GREEN}BACKUP DIRECTORY CREATED${RESET}"
        sleep 1
        checkHARD_DRIVE
    fi
fi
