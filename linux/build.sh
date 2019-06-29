#!/bin/bash
set -e
##########################################
# This script is used to build A64 Linux.
# by: Qitas
# Date: 2019-03-26
##########################################
export ROOT=`pwd`
SCRIPTS=$ROOT/scripts
export BOOT_PATH
export ROOTFS_PATH
export UBOOT_PATH

function git_configure()
{
    export GIT_CURL_VERBOSE=1
    export GIT_TRACE_PACKET=1
    export GIT_TRACE=1    
}
function gcc_prepare()
{ 
	sudo apt -y --no-install-recommends --fix-missing install \
	bsdtar mtools u-boot-tools pv bc \
	gcc automake make \
	lib32z1 lib32z1-dev qemu-user-static \
	dosfstools
}

function get_toolchain()
{ 
	if [ ! -d $ROOT/toolchain/gcc-linaro-aarch ]; then
		cd $ROOT
		git clone --depth=1 https://github.com/sochub/aarch-linux.git
		mv aarch-linux toolchain
    	fi
	if [ ! -d $ROOT/toolchain/gcc-linaro-aarch/gcc-linaro ]; then
		cd $ROOT/toolchain/gcc-linaro-aarch
		git clone --depth=1 https://github.com/sochub/arm-linux-eabi.git
		mv arm-linux-eabi gcc-linaro
    	fi
}


Udisk_P()
{
	cd $ROOT/scripts
	./Notice.sh
	cd -
}
root_check()
{
	if [ "$(id -u)" -ne "0" ]; then
		echo "This option requires root."
		echo "Pls use command: sudo ./build.sh"
		exit 0
	fi	
}

UBOOT_check()
{
	Udisk_P
	for ((i = 0; i < 5; i++)); do
		UBOOT_PATH=$(whiptail --title "A64 Build System" \
			--inputbox "Pls input device node of SDcard.(/dev/sdb)" \
			10 60 3>&1 1>&2 2>&3)
	
		if [ $i = "4" ]; then
			whiptail --title "A64 Build System" --msgbox "Error, Invalid Path" 10 40 0	
			exit 0
		fi


		if [ ! -b "$UBOOT_PATH" ]; then
			whiptail --title "A64 Build System" --msgbox \
				"The input path invalid! Pls input correct path!" \
				--ok-button Continue 10 40 0	
		else
			i=200 
		fi 
	done
}

BOOT_check()
{
	## Get mount path of u-disk
	for ((i = 0; i < 5; i++)); do
		BOOT_PATH=$(whiptail --title "A64 Build System" \
			--inputbox "Pls input mount path of BOOT.(/media/A64/BOOT)" \
			10 60 3>&1 1>&2 2>&3)
	
		if [ $i = "4" ]; then
			whiptail --title "A64 Build System" --msgbox "Error, Invalid Path" 10 40 0	
			exit 0
		fi


		if [ ! -d "$BOOT_PATH" ]; then
			whiptail --title "A64 Build System" --msgbox \
				"The input path invalid! Pls input correct path!" \
				--ok-button Continue 10 40 0	
		else
			i=200 
		fi 
	done
}

ROOTFS_check()
{
	for ((i = 0; i < 5; i++)); do
		ROOTFS_PATH=$(whiptail --title "A64 Build System" \
			--inputbox "Pls input mount path of rootfs.(/media/A64/rootfs)" \
			10 60 3>&1 1>&2 2>&3)
	
		if [ $i = "4" ]; then
			whiptail --title "A64 Build System" --msgbox "Error, Invalid Path" 10 40 0	
			exit 0
		fi


		if [ ! -d "$ROOTFS_PATH" ]; then
			whiptail --title "A64 Build System" --msgbox \
				"The input path invalid! Pls input correct path!" \
				--ok-button Continue 10 40 0	
		else
			i=200 
		fi 
	done
}

if [ ! -d $ROOT/output ]; then
    mkdir -p $ROOT/output
fi

git_configure
gcc_prepare
get_toolchain

export PLATFORM="winA64"

##########################################
## Root Password check
for ((i = 0; i < 5; i++)); do
	PASSWD=$(whiptail --title "A64 Build System" \
		--passwordbox "Enter root password instead of using sudo to run this!" \
		10 60 3>&1 1>&2 2>&3)
	
	if [ $i = "4" ]; then
		whiptail --title "Note Box" --msgbox "Error, Invalid password" 10 40 0	
		exit 0
	fi

	sudo -k
	if sudo -lS &> /dev/null << EOF
$PASSWD
EOF
	then
		i=10
	else
		whiptail --title "A64 Build System" --msgbox "Invalid password, Pls input corrent password" \
			10 40 0	--cancel-button Exit --ok-button Retry
	fi
done

echo $PASSWD | sudo ls &> /dev/null 2>&1


OPTION=$(whiptail --title "A64 Build System" \
	--menu "$MENUSTR" 20 60 12 --cancel-button Finish --ok-button Select \
	"0"   "Build Release Image" \
	"1"   "Build Rootfs" \
	"2"	  "Build Uboot" \
	"3"   "Build Linux" \
	"4"   "Build Kernel only" \
	"5"   "Build Module only" \
	"6"   "Install Image into SDcard" \
	"7"   "Update kernel Image" \
	"8"   "Update Module" \
	"9"   "Update Uboot" \
	"10"  "Update SDK to Github" \
	"11"  "Update SDK from Github" \
	3>&1 1>&2 2>&3)

if [ $OPTION = "0" -o $OPTION = "1" ]; then
	sudo echo ""
	clear
	TMP=$OPTION
	TMP_DISTRO=""
	MENUSTR="Distro Options"
	OPTION=$(whiptail --title "A64 Build System" \
		--menu "$MENUSTR" 20 60 5 --cancel-button Finish --ok-button Select \
		"0"   "Ubuntu"\		
		"1"   "Arch" \
		"2"   "Debian Sid" \
		"3"   "Debian Jessie" \
		"4"   "CentOS" \
		3>&1 1>&2 2>&3)

	if [ ! -f $ROOT/output/uImage ]; then
		export BUILD_KERNEL=1
		cd $SCRIPTS
		./kernel_compile.sh
		cd -
	fi
	if [ ! -d $ROOT/output/lib ]; then
		export BUILD_MODULE=1
		cd $SCRIPTS
		./kernel_compile.sh
		cd -
	fi
	if [ $OPTION = "1" ]; then
		TMP_DISTRO="arch"
	elif [ $OPTION = "0" ]; then
		TMP_DISTRO="ubuntu"	
	elif [ $OPTION = "2" ]; then
		TMP_DISTRO="sid"
	elif [ $OPTION = "3" ]; then
		TMP_DISTRO="jessie"
	elif [ $OPTION = "4" ]; then
		TMP_DISTRO="centeros"
	fi
	cd $SCRIPTS
	DISTRO=$TMP_DISTRO
	if [ -d $ROOT/output/${DISTRO}_rootfs ]; then
		if (whiptail --title "A64 Build System" --yesno \
			"${DISTRO} rootfs has exist! Do you want use it?" 10 60) then
			OP_ROOTFS=0
		else
			OP_ROOTFS=1
		fi
		if [ $OP_ROOTFS = "0" ]; then
			sudo cp -rf $ROOT/output/${DISTRO}_rootfs $ROOT/output/tmp
			if [ -d $ROOT/output/rootfs ]; then
				sudo rm -rf $ROOT/output/rootfs
			fi
			sudo mv $ROOT/output/tmp $ROOT/output/rootfs
			whiptail --title "A64 Build System" --msgbox "Rootfs has build" \
				10 40 0	--ok-button Continue
		else
			sudo ./00_rootfs_build.sh $DISTRO
			sudo ./01_rootfs_build.sh $DISTRO
			sudo ./02_rootfs_build.sh $DISTRO
			sudo ./03_rootfs_build.sh $DISTRO

		fi
	else
		sudo ./00_rootfs_build.sh $DISTRO
		sudo ./01_rootfs_build.sh $DISTRO
		sudo ./02_rootfs_build.sh $DISTRO
		sudo ./03_rootfs_build.sh $DISTRO
	fi
	if [ $TMP = "0" ]; then 
		sudo ./build_image.sh $PLATFORM
		whiptail --title "A64 Build System" --msgbox "Succeed to build Image" \
				10 40 0	--ok-button Continue
	fi
	exit 0
elif [ $OPTION = "2" ]; then
	cd $SCRIPTS
	./uboot_compile.sh
	clear
	exit 0
elif [ $OPTION = "3" ]; then
	export BUILD_KERNEL=1
	export BUILD_MODULE=1
	cd $SCRIPTS
	./kernel_compile.sh
	exit 0
elif [ $OPTION = "4" ]; then
	export BUILD_KERNEL=1
	cd $SCRIPTS
	./kernel_compile.sh
	exit 0
elif [ $OPTION = "5" ]; then
	export BUILD_MODULE=1
	cd $SCRIPTS
	./kernel_compile.sh
	exit 0
elif [ $OPTION = "6" ]; then
	UBOOT_check
	clear
	whiptail --title "A64 Build System" \
			 --msgbox "Downloading Image into SDcard. Pls select Continue button" \
				10 40 0	--ok-button Continue
	sudo dd bs=1M if=$ROOT/output/${PLATFORM}.img of=$UBOOT_PATH && sync
	clear
	whiptail --title "A64 Build System" --msgbox "Succeed to Download Image into SDcard" \
				10 40 0	--ok-button Continue
	exit 0
elif [ $OPTION = '7' ]; then
	clear 
	BOOT_check
	clear
	cd $SCRIPTS
	sudo ./kernel_update.sh $BOOT_PATH
	exit 0
elif [ $OPTION = '8' ]; then
	sudo echo ""
	clear 
	ROOTFS_check
	clear
	cd $SCRIPTS
	sudo ./modules_update.sh $ROOTFS_PATH
	exit 0
elif [ $OPTION = '9' ]; then
	clear
	UBOOT_check
	clear
	cd $SCRIPTS
	sudo ./uboot_update.sh $UBOOT_PATH
	exit 0
elif [ $OPTION = "10" ]; then
	clear
	echo -e "\e[1;31m Updating SDK to Github \e[0m"
	git push -u origin master
	exit 0
elif [ $OPTION = "11" ]; then
	clear
	echo -e "\e[1;31m Updating SDK from Github \e[0m"
	git pull
	exit 0
else
	whiptail --title "A64 Build System" \
		--msgbox "Pls select correct option" 10 50 0
	exit 0
fi
