#!/bin/bash
SYSTEM="/dev/mmcblk0"
HARD_DRIVE_TEMP="/tmp/ARG0-HDSWAP"
BACKUP_DIR="/mnt/mass/"
BACKUP_COUNT=5
EXPECTED_COUNT=2

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
    echo "\e[1;37mRaspberry Pi Backup Utility \e[1;32m~ \e[1;37mhttps://barisalbayrak.net/\e[0m"
    echo "-------------------------------------------------------------"
    dd if=$SYSTEM bs=128K status=progress | gzip > ${BACKUP_DIR}${IMAGE_NAME}
} 

ejectHARD_DRIVE() {
    echo ""
    umount -l $HARD_DRIVE
}

startBackup() {
    clear
echo "\e[1;32m⠀⢀⣠⣤⣶⣶⣶⣤⣄⠀⠀⣀⣤⣶⣶⣶⣤⣄⡀⠀
⠀⢸⣿⠁⠀⠀⠀⠀⠙⢷⡾⠋⠀⠀⠀⠀⠈⣿⡇⠀
⠀⠘⢿⡆⠀⠀⠀⠢⣄⣼⣧⣠⠔⠀⠀⠀⢰⡿⠃⠀
⠀⠀⠈⠻⣧⣤⣀⣤⣾⣿⣿⣷⣤⣀⣤⣼⠟⠁⠀⠀
\e[1;31m⠀⠀⣰⡾⠋⠉⣩⣟⠁⠀⠀⠈⣻⣍⠉⠙⢷⣆⠀⠀
⠀⢀⣿⣀⣤⡾⠛⠛⠷⣶⣶⠾⠛⠛⢷⣤⣀⣿⡀⠀
⣰⡟⠉⣿⡏⠀⠀⠀⠀⢹⡏⠀⠀⠀⠀⢹⣿⠉⢻⣆
⣿⡇⠀⣿⣇⠀⠀⠀⣠⣿⣿⣄⠀⠀⠀⣸⣿⠀⢸⣿
⠙⣷⣼⠟⠻⣿⣿⡿⠋⠁⠈⠙⢿⣿⣿⠟⠻⣧⣾⠋
⠀⢸⣿⠀⠀⠈⢿⡇⠀⠀⠀⠀⢸⡿⠁⠀⠀⣿⡇⠀
⠀⠀⠻⣧⣀⣀⣸⣿⣶⣤⣤⣶⣿⣇⣀⣀⣼⠟⠀⠀
⠀⠀⠀⠈⠛⢿⣿⣿⡀⠀⠀⢀⣿⣿⡿⠛⠁⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠙⠻⠿⠿⠟⠋⠀⠀⠀⠀⠀⠀⠀\e[0m
"
    echo "\e[0;37mStarting backup process on \e[1;32m~ \e[1;36m$HARD_DRIVE\e[0m "
    echo "\e[0;37mThis process can take up to several hours depending on the system size."
    echo "\e[1;31mDON'T WRITE ANY DATA TO THE SYSTEM AND DON'T PULL OF BACKUP STORAGE DURING THIS TIME!\e[0m"
    # createImage
    sleep 3
    checkImages
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
        echo "\e[1;36mLATEST BACKUP FILE:\n\e[1;37mFile: \e[1;31mFAILED \e[1;37m| Size: \e[1;31m0 MB \e[1;37m|"
    else
        echo "\e[1;36mLATEST BACKUP FILE:\n\e[1;37mFile: \e[1;32m$FILENAME \e[1;37m| Size: \e[1;32m$FILESIZE_MB MB \e[1;37m| Modification Date: \e[1;32m$NEW_DATE\e[0m"
    fi

    ejectHARD_DRIVE
}

listDevices() {
    echo ""

    lsblk --output NAME,TYPE | awk '
    NR == 1 {print $0}
    NR > 1 {
        if (NR > 1 && $2 == "part") {
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

checkHARD_DRIVE() {
    if [ -f "$HARD_DRIVE_TEMP" ]; then
        HARD_DRIVE=$(cat "$HARD_DRIVE_TEMP")
        if ! mount | grep -q "$HARD_DRIVE" && lsblk -o NAME | grep -q "$HARD_DRIVE"; then
            listDevices
            echo "$(cat "$HARD_DRIVE_TEMP") DEVICE DISCONNECTED"
            echo "\e[1;37mENTER HARD DRIVE MOUNT POINT: \e[1;32m~ \e[1;36m(ex: /dev/sda1):\e[0m "
            read INPUT_DRIVE
            HARD_DRIVE=$(echo "$INPUT_DRIVE" | sed 's:/*$::')
            echo "$HARD_DRIVE" > "$HARD_DRIVE_TEMP"
        fi
    else
        listDevices
        echo "\e[1;37mENTER HARD DRIVE MOUNT POINT: \e[1;32m~ \e[1;36m(ex: /dev/sda1):\e[0m "
        read INPUT_DRIVE
        HARD_DRIVE=$(echo "$INPUT_DRIVE" | sed 's:/*$::')
        echo "$HARD_DRIVE" > "$HARD_DRIVE_TEMP"
    fi
}

checkHARD_DRIVE

checkImages() {
    echo ""
    cd "$BACKUP_DIR" || exit

    FILE_COUNT=$(ls -t | wc -l)
    if [ "$FILE_COUNT" -gt "$BACKUP_COUNT" ]; then
        FILES_TO_DEL=$(ls -t | tail -n +"$EXPECTED_COUNT")
        for FILE in $FILES_TO_DEL; do
            echo "\e[1;37m$FILE \e[1;32m~ \e[1;31mOLD BACKUP FILE HAS BEEN REMOVED FROM \e[1;36m$BACKUP_DIR\e[0m"
            rm -f "$FILE"
        done
    fi

    latestImage
}

mountFunction() {
    if mountpoint -q "$BACKUP_DIR"; then
        echo "\e[1;36m$HARD_DRIVE\e[0m \e[1;37malready mounted on >>> \e[1;33m$BACKUP_DIR\e[0m";
        startBackup
    else
        echo "mounting \e[1;36m$HARD_DRIVE\e[0m\n\e[1;31mDON'T PULL OFF YOUR STORAGE DEVICE...\e[0m";
        mount "$HARD_DRIVE" "$BACKUP_DIR" 2>/dev/null
        sleep 3
        echo "\e[1;36m$HARD_DRIVE\e[0m \e[1;37mmounted on >>> \e[1;33m$BACKUP_DIR\e[0m";
        startBackup
    fi
}

if [ -d "$BACKUP_DIR" ]; then
    mountFunction
else
    mkdir "$BACKUP_DIR" >/dev/null 2>&1
    sleep 2
    mountFunction
fi