
<a class="filter" href="https://choosealicense.com/licenses/mit/"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License"></a>

<h1 class='filter'>Raspberry Pi Backup Utility</h1>

![Raspberry Pi Backup Utility Bash Screen](https://raw.githubusercontent.com/barisalby/gist/main/images/Raspberry%20Pi%20Backup%20Utility/2rw95-hwju0.gif)

Designed specifically for Raspberry Pi devices, this backup program provides gzip-powered instant compression when creating images. This allows you to effectively compress and backup disk images of your Raspberry Pi systems. Furthermore, this tool supports Debian Bookworm as well as all other distributions.

Script is coded thinking Crontab installation compability. After once introducing your backup device, no further input is expected from you. After the process is complete, it outputs a result and unmounts your device for security purposes. At the script each start, it checks whether the device is connected or not, and if there is no device on the previously connected slot, you will be prompted to identify your current backup device. Unlike the standard `dd` image creation method, it performs instant `gzip compression` every `128K blocks`. In the example data, a `58 GB` image is reduced to about `3 GB`. Loss tests were performed and successful results were obtained. Since multiple backup files over time are likely to cause storage space problems in your backup path, the oldest `2` backup files are deleted from the hard disk depending on the creation date every `5` backups. If you want to customize this value, please check **Warnings** section.

Also see the end of this article for Cron installation instructions.

## 🚨 Warnings

### Customize System Destination
If you are using a Raspberry Pi external device or if your operating system is running from a different drive on your RPI device, please configure the following line in the script file before starting this process.

`SYSTEM="/dev/mmcblk0"`

**mmcblk0**: Multi Media Card

### Backup Limit on Mass Storage
If you want to update the target number to check for old backups, update the `BACKUP_COUNT` variable in the script. Changing this value will cause the condition checker to edit.

You can update the number of data to be deleted via the `EXPECTED_COUNT` variable.

**Default Values:**
`BACKUP_COUNT=5`
`EXPECTED_COUNT=2` 

## ⛓️ Dependencies

Dependent packages are given below. These are the packages that come installed in almost every Linux distribution.
```bash
  lsblk
  dd
  gzip
```

## 🚀 Installation

First of all clone the repo to your device using the link below.
```bash
  $ git clone git@github.com:barisalby/rpi-backup-utility.git
  $ cd rpi-backup-utility
```

Update all your packages.
```bash
  $ sudo apt update -y
  $ clear
```
Run bash script with superadmin privilages.
```bash
  $ sudo sh rpi_backup_utility.sh
```
Here you need to define the location where the device image will be backed up.
Your sda, sdb, sdc and NVMe spaces will be colored on the lsblk. The displayed values list your connected devices. Devices with ExFAT file system do not need any partition. In such a case, the location you need to assign will be /dev/sda. Devices with other file systems come with one or more partitions. In this case the path you need to assign will be /dev/sdaX. 

`X = Partition number`

```bash
  NAME        TYPE
  loop0       loop
  loop1       loop
  loop2       loop
  sda         disk
  mmcblk0     disk
  ├─mmcblk0p1 part
  └─mmcblk0p2 part

ENTER HARD DRIVE MOUNT POINT: ~ (ex: /dev/sda1):
````
Sit back and the rest of the process will start automatically. \
\
**DON'T WRITE ANY DATA TO THE SYSTEM AND DON'T PULL OFF BACKUP STORAGE DURING THIS TIME!**\

At the end of the process you will get a like below type result output.
```bash
LATEST BACKUP FILE:
File: F5-RASP-ARG0-2023-11-18.img.gz | Size: 2811.87 MB | Modification Date: 2023-11-18 18:19
```
## Crontab Installation
You need to perform cron operations to run the script automatically at certain times and to take a backup to an already mounted device.

Firstly run crontab.
```bash
$ sudo crontab -e
```
You'll see the following lines. Select any editor and continue.
```bash
Select an editor.  To change later, run 'select-editor'.
  1. /bin/nano        <---- easiest
  2. /usr/bin/vim.tiny
  3. /bin/ed

Choose 1-3 [1]:
```
Add the following line at the bottom of the displayed comment lines. \
This line means run the relevant script at 3 AM on the first day of every month.
```bash
0 3 1 * * sudo sh /path/to/rpi_backup_utility.sh
```

### Simple Crontab Scheme

```bash
* * * * * command to be executed
- - - - -
| | | | |
| | | | ------ Day of week (0 - 7) (Sunday=0 or 7)
| | | ------- Month (1 - 12)
| | --------- Day of month (1 - 31)
| ----------- Hour (0 - 23)
------------- Minute (0 - 59)
```

*Enjoy it!*
