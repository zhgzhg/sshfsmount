#!/bin/bash
# (C) 06.10.2013 zhgzhg

############### configuration #####################

MOUNTPATH="$HOME/sshfsmount"

###################################################

typeset RETCODE

# check if mount path exists

echo Checking for $MOUNTPATH ...

if [ ! -d $MOUNTPATH ]; then

	echo Missing! You need to configure MOUNTPATH script variable!
	exit 1
else
	echo Presented! Testing for write permissions...
	
	TEMPWDIRTEST="write_test_$RANDOM";
	mkdir $MOUNTPATH/$TEMPWDIRTEST >/dev/null 2>&1
	RETCODE=$?

	if [ $RETCODE -ne 0 ]; then
		echo Fail! You do not have write permissions in $MOUNTPATH !
		if [ "$(id -u)" != "0" ]; then
				echo [Try to run this script as root!]
		fi	
		exit 1
	else
		echo Success!
		rmdir $MOUNTPATH/$TEMPWDIRTEST >/dev/null 2>&1
	fi
	
fi

# check for available sshfs executable

sshfs -h >/dev/null 2>&1
RETCODE=$?

if [ $RETCODE -eq 127 ]; then
	echo -e "You need to install sshfs!";
	echo -e "For Fedora under root run \"yum install sshfs\" and \"yum install fuse-sshfs\".";
	exit 1
fi

declare -a dirs
i=1
for d in $MOUNTPATH/*
do
    dirs[i++]="${d%/}"
done

if [ "${dirs[1]}" == "$MOUNTPATH/*" ]; then
	echo -e "\nNo available directories inside $MOUNTPATH !"
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

if [ $INDEX -eq 0 ]; then
	echo Canceled!
	exit 1
fi


echo -e "Unmounting ${dirs[$INDEX]}..."

fusermount -u ${dirs[$INDEX]}

echo -e "Removing ${dirs[$INDEX]}..."

rmdir ${dirs[$INDEX]}

echo Done!
