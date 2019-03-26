#!/bin/bash
set -e
#####################################
# This script is used to build A64 Linux.
# by: Qitas
# Date: 2019-03-26
## Install cross toolchain
#####################################

if [ -z $TOOT ]; then
	ROOT=`cd .. && pwd`
fi

TOOLS="$ROOT/toolchain"
TOOLTARXZ="$ROOT/toolchain/toolchain_tar/toolchain"
TOOLTAR="$ROOT/toolchain/toolchain.tar.gz"

whiptail --title "A64 Build System" --msgbox "Installing Cross-Tools. Pls wait a mount." --ok-button Continue 10 40 0

clear
echo -e "\e[1;31m Uncompress toolchain.. \e[0m"
cat ${TOOLTARXZ}* > ${TOOLTAR}

tar xzvf $TOOLTAR -C $ROOT/toolchain
mv $ROOT/toolchain/toolchain/* $ROOT/toolchain
rm -rf $ROOT/toolchain/toolchain
rm -rf $TOOLTAR 

whiptail --title "A64 Build System" --msgbox "Cross-Tools has installed." 10 40 0


