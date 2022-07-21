#! /bin/bash

# Linux Image Utility (LinuxImageUtil)
# --------------------------------
# author    : SonyaCore
#	      https://github.com/SonyaCore

# Global Variables:
shopt -s nullglob
title="Welcome to Linux Image Utility (LinuxImageUtil) Program"

# $TERM variable may be missing when called via desktop shortcut
CurrentTERM=$(env | grep TERM)
if [[ $CurrentTERM == "" ]] ; then
    notify-send --urgency=critical \ 
                "$0 cannot be run from GUI without TERM environment variable."
    exit 1
fi

# Must run as root
if [[ $(id -u) -ne 0 ]] ; then echo "Usage: sudo $0" ; exit 1 ; fi

# Check if Required Packed Is Installed
PackageCheck(){
REQUIRED_PKG="whiptail"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
echo Checking for $REQUIRED_PKG: $PKG_OK
if [ "" = "$PKG_OK" ]; then
  echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
  sudo apt-get --yes install $REQUIRED_PKG
fi

REQUIRED_PKG="dialog"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
echo Checking for $REQUIRED_PKG: $PKG_OK
if [ "" = "$PKG_OK" ]; then
  echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
  sudo apt-get --yes install $REQUIRED_PKG
fi

REQUIRED_PKG="gzip"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
echo Checking for $REQUIRED_PKG: $PKG_OK
if [ "" = "$PKG_OK" ]; then
  echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
  sudo apt-get --yes install $REQUIRED_PKG
fi

REQUIRED_PKG="tar"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
echo Checking for $REQUIRED_PKG: $PKG_OK
if [ "" = "$PKG_OK" ]; then
  echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
  sudo apt-get --yes install $REQUIRED_PKG
fi
REQUIRED_PKG="zstd"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
echo Checking for $REQUIRED_PKG: $PKG_OK
if [ "" = "$PKG_OK" ]; then
  echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
  sudo apt-get --yes install $REQUIRED_PKG
fi
clear
}
PackageCheck

mainmenu(){
	if [ "${1}" = "" ]; then
		nextitem="."
	else
		nextitem=${1}
	fi
	options=()
	options+=("${txtimage}" "")
	options+=("${txtcreateimage}" "")
	options+=("${txtdiskpartmenu}" "")
	options+=("${txteditor}" "(${txtoptional})")
	options+=("" "")
	options+=("${txtreboot}" "")
	sel=$(whiptail --backtitle "${title}" --title "${txtmainmenu}" --menu "" --cancel-button "${txtexit}"  --default-item "${nextitem}" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ "$?" = "0" ]; then
		case ${sel} in
			"${txtimage}")
				image_restore
				nextitem="${txtcreateimage}"
			;;
			"${txtcreateimage}")
				makeimage
				nextitem="${txtdiskpartmenu}"
			;;
			"${txtdiskpartmenu}")
				diskpartmenu
				nextitem="${txteditor}"
			;;
			"${txteditor}")
				chooseeditor
				nextitem="${txtreboot}"
			;;
			"${txtreboot}")
				rebootsystem
				nextitem="${txtreboot}"
			;;
		esac
		mainmenu "${nextitem}"
	elif [ "$?" = "1" ]; then
		exit
	else
		clear
	fi
}

# initialise trap to call trap_ctrlc function
# when signal 2 (SIGINT) is received
#trap trap_ctrlc 2

function trap_ctrlc ()
{
	echo ""
}


function returnmain()
if [ $? -eq 1 ] ;then
clear
mainmenu
fi


exitcode(){
echo "Program Exited With Code $?"

}

selectdisk(){
                items=$(lsblk -p -n -l -o NAME,FSTYPE,LABEL,SIZE,MOUNTPOINT -e 7,11)
                options=()
                IFS_ORIG=$IFS
                IFS=$'\n'
                for item in ${items}
                do
                                options+=("${item}" "")
                done
                IFS=$IFS_ORIG
                result=$(whiptail --title "${1}" --menu "" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
                if [ "$?" != "0" ]
                then
                                return 1
                fi
                echo ${result%%\ *}
                return 0
}

selectonlydisk(){
                items=$(lsblk -p -d -n -l -o NAME,FSTYPE,LABEL,SIZE,MOUNTPOINT -e 7,11)
                options=()
                IFS_ORIG=$IFS
                IFS=$'\n'
                for item in ${items}
                do
                                options+=("${item}" "")
                done
                IFS=$IFS_ORIG
                result=$(whiptail --title "${1}" --menu "" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
                if [ "$?" != "0" ]
                then
                                return 1
                fi
                echo ${result%%\ *}
                return 0
}

fileselect(){
                items=$(ls -1 *.{iso,gz,img} )
                options=()
                IFS_ORIG=$IFS
                IFS=$'\n'
                for item in ${items}
                do
                                options+=("${item}" "")
                done
                IFS=$IFS_ORIG
                result=$(whiptail  --title "DD Image Restore" --menu "Select Image" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
                if [ "$?" != "0" ]
                then
                                return 1
                fi
                echo ${result%%\ *}
                return 0
}


# open fd
exec 3>&1

image_restore(){

IMAGESELECT=$(fileselect)
returnmain
DISKSELECT=$(selectdisk)
returnmain

#exec 3>&1
bs='2M'
conv='notrunc,noerror'

dialog                                             \
--no-cancel                                        \
--separate-widget $'\n'                            \
--title "Switch Options"                           \
--form ""                                          \
0 0 0                                              \
"bs:"          1 1     "$bs"         1 10 30 0     \
"flags:"       2 1     "$conv"       2 10 30 0     \
2>&1 1>&3 | {
    read -r bs
    read -r conv
}

#exec 3>&-


if (whiptail --title "Confirmation" --yesno "Are You Sure to dd\nimage : $IMAGESELECT in disk: $DISKSELECT ?\n$txtformatdeviceconfirm" 10 80) then

(pv -n $IMAGESELECT | gunzip | dd of=$DISKSELECT bs=$bs conv=$conv &> log.txt ) 2>&1 | whiptail --gauge "Running dd command\n(restoring $IMAGESELECT on $DISKSELECT), please wait..." 10 70 0

whiptail --title 'DD Completed.' --msgbox "`cat log.txt`" 10 100
if [ $? -eq 0 ] ;then
mainmenu
fi
else
    exitcode
fi
}


makeimage() {
echo -e "\033[0;35mDD ImageCreator\n\n\033[01;37m"
    echo ""
    echo "======================================"
    echo "      Select the disk to be used      "
    echo "======================================"
    lsblk
    echo -e '\n'
    echo "======================================"
    echo "Don't forget the disk prefix, example:"
    echo "         /sda1, /sda2, /sda3, /sda4 .."
    echo "======================================"
    echo
    read -p "Type here:" disk
    clear

	if [ $disk == "quit" ]; then
	#exit 0
	mainmenu
	elif [ $disk == "q" ]; then
	#exit 0
	mainmenu
	fi

    echo ""
    echo " Press CTRL+C to stop or wait 5sec to "
    echo "             continue."
    sleep 5
    clear
    echo ""

version=20.04
type=server
size=17000

# restore command
dd if=/dev$disk bs=1M count=$size status=progress | gzip -c > ubuntu-$version-$type-`date +%F`.img.gz
}

diskpartmenu(){
	if [ "${1}" = "" ]; then
		nextitem="."
	else
		nextitem=${1}
	fi
	options=()
	options+=("${txteditgparted} (GParted)" "")
	options+=("${txteditparts} (cfdisk)" "")
	options+=("${txteditparts} (cgdisk)" "")
	options+=("${txteditparts} (fdisk)" "")
	options+=("${txteditparts} (gdisk)" "")
	sel=$(whiptail --backtitle "${apptitle}" --title "${txtdiskpartmenu}" --menu "" --cancel-button "${txtback}" --default-item "${nextitem}" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ "$?" = "0" ]; then
		case ${sel} in
		
			"${txteditgparted} (GParted)")
				diskpartgparted
				nextitem="${txteditgparted} (GParted)"
			;;
			"${txteditparts} (cfdisk)")
				diskpartcfdisk
				nextitem="${txteditparts} (cfdisk)"
			;;
			"${txteditparts} (cgdisk)")
				diskpartcgdisk
				nextitem="${txteditparts} (cgdisk)"
			;;
			"${txteditparts} (fdisk)")
				diskpartfdisk
				nextitem="${txteditparts} (fdisk)"
			;;
			"${txteditparts} (gdisk)")
				diskpartgdisk
				nextitem="${txteditparts} (gdisk)"
			;;
		esac
		diskpartmenu "${nextitem}"
	fi
}
diskpartgparted(){
		device=$( selectonlydisk "${txteditgparted} (GUI Partition Manager)" )
	if [ "$?" = "0" ]; then
		clear
		gparted ${device}
	fi
}
diskpartcfdisk(){
		device=$( selectdisk "${txteditparts} (cfdisk)" )
	if [ "$?" = "0" ]; then
		clear
		cfdisk ${device}
	fi
}

diskpartcgdisk(){
		device=$( selectdisk "${txteditparts} (cgdisk)" )
	if [ "$?" = "0" ]; then
		clear
		cgdisk ${device}
	fi
}

diskpartfdisk(){
		device=$( selectdisk "${txteditparts} (fdisk)" )
	if [ "$?" = "0" ]; then
		clear
		fdisk ${device}
	fi
}
diskpartgdisk(){
		device=$( selectdisk "${txteditparts} (gdisk)" )
	if [ "$?" = "0" ]; then
		clear
		gdisk ${device}
	fi
}



rebootsystem(){
whiptail --yesno "Reboot?" 10 30
if [ $? -eq 0 ] ;then
sleep 1 | TERM=ansi whiptail  --title "Reboot" --infobox "Rebooting System.." 9 30
clear && reboot
elif [ $? -eq 1 ] ;then
mainmenu
fi
}


pressanykey(){
	read -n1 -p "${txtpressanykey}"
}

chooseeditor(){
	options=()
	options+=("nano" "")
	options+=("vim" "")
	options+=("vi" "")
	options+=("edit" "")
	sel=$(whiptail --backtitle "${apptitle}" --title "${txteditor}" --menu "" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ "$?" = "0" ]; then
		clear
		echo "export EDITOR=${sel}"
		export EDITOR=${sel}
		EDITOR=${sel}
		pressanykey
	fi
}

# --------------------------------------------------------
loadstrings(){

	locale=en_US.UTF-8
	#font=

	txtexit="Exit"
	txtback="Back"
	txtignore="Ignore"

	txtmainmenu="Main Menu"
	txtimage="Restore Image"
	txtcreateimage="Create Image"
	txteditor="Editor"
	txtdiskpartmenu="Disk Partitioning"
	txtreboot="Reboot"

	txteditparts="Edit Partitions"
	txteditgparted="Launch GParted"
	
	txtformatdeviceconfirm="Warning, all data on selected devices will be erased ! \nFormat device ?"
	
	txtoptional="Optional"
	txtset="Set %1"
	txtgenerate="Generate %1"
	txtedit="Edit %1"
	txtinstall="Install %1"
	txtenable="Enable %1"

	txtpressanykey="Press any key to continue."
}
# --------------------------------------------------------

loadstrings
mainmenu
trap trap_ctrlc 2
