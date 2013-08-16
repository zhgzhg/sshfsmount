#!/bin/bash
# (C) 15-16.08.2013 zhgzhg

if [ "$(id -u)" != "0" ]; then
   echo [You need to run this as root!]
   exit 1
fi

typeset RETCODE

sshfs -h >&/dev/null
RETCODE=$?

if [ $RETCODE == 127 ]; then
	echo -e "You need to install sshfs!";
	echo -e "For Fedora under root run \"yum install sshfs\" and \"yum install fuse-sshfs\".";
	exit 1
fi

declare -a dirs
i=1
for d in /mnt/*
do
    dirs[i++]="${d%/}"
done

if [ "${dirs[1]}" == "/mnt/*" ]; then
	echo -e "No available directories inside /mnt !"
	exit 1
fi

echo -e "\nDirectories list (for unmounting are those with \"VM_\" prefix):\n"

echo "[ 0 ]:  Cancel"

for((i=1;i<=${#dirs[@]};i++))
do
    echo "[" $i "]: " "${dirs[i]}"
done

echo -ne "\nChoose the directory you want to unmount: "

INDEX=""
read -e INDEX;

if [ "$INDEX" -eq 0 ]; then
	echo Canceled!
	exit 1
fi


echo -e "Unmounting ${dirs[$INDEX]}..."

fusermount -u ${dirs[$INDEX]}

echo -e "Removing ${dirs[$INDEX]}..."

rmdir ${dirs[$INDEX]}

echo Done!
