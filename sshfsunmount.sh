#!/bin/bash
# (C) 17.10.2013 zhgzhg
# semi-silent mode format: sshfsunount.sh [--unmount <full_path>][-1][-2]
# --unmount <full_path_to_the_directory_to_be_unmounted>
# -1 unmounts all directories inside the default MOUNTPATH
# -2 forced unmount of all inside the default MOUNTPATH

############### configuration #####################

MOUNTPATH="$HOME/sshfsmount"

###################################################

INSILENTMODE=0

if [ -n "$1" ]; then
	if [[ -n "$2" && "$1" == "--unmount" ]]; then
		INSILENTMODE=1
		MOUNTPATH=$2
	elif [[ "$1" == "-1" || "$1" == "-2" ]]; then
		INSILENTMODE=$1
	else
		echo -e "Invalid parameters! Must be --unmount <directory_full_path>"
		echo -e "or -1 or -2 for normal/force unmount of all directories"
		echo -e "inside the set default path."
		exit 1;
	fi
fi

typeset RETCODE

# check if mount path exists

echo Checking for $MOUNTPATH ...

if [ ! -d $MOUNTPATH ]; then
	if [ $INSILENTMODE -eq 1 ]; then
		echo Missing! Check your path and directory name!
	else
		echo Missing! You need to configure MOUNTPATH script variable!
	fi	
	exit 1
else
	echo -n "Presented! "
	
	if [ $INSILENTMODE -eq 0 ]; then
		echo Testing for write permissions...
	else
		echo Write permissions testing is skipped in this mode!
	fi
	
	TEMPWDIRTEST="write_test_$RANDOM";
	
	if [ $INSILENTMODE -eq 0 ]; then
		mkdir $MOUNTPATH/$TEMPWDIRTEST >/dev/null 2>&1
		RETCODE=$?
	else
		RETCODE=0
	fi

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
	echo -e "For Ubuntu run \"sudo apt-get install fuse-utils sshfs\"."
	echo -e "For Mandriva run \"urpmi fuse-utils sshfs\".";
	exit 1
fi

declare -a dirs
i=1
if [ $INSILENTMODE -ne 1 ]; then
	for d in $MOUNTPATH/*
	do
		dirs[i++]="${d%/}"
	done

	if [ "${dirs[1]}" == "$MOUNTPATH/*" ]; then
		echo -e "\nNo available directories inside $MOUNTPATH !"
		exit 1
	fi
else
	dirs[i++]="$MOUNTPATH"
fi

if [ $INSILENTMODE -eq 0 ]; then
	echo -e "\nDirectories list (for unmounting are those with \"VM_\" prefix):\n"

	echo "[ -2 ]: Force unmount everything"
	echo -e "[ -1 ]: Unmount everything\n"
	echo -e "[ 0 ]:  Cancel\n"

	for((i=1;i<=${#dirs[@]};i++))
	do
		echo "[" $i "]: " "${dirs[i]}"
	done

	echo -e "\nChoose the directory you want to unmount: "
fi

ENDOFINDEX=0
INDEX=""

if [ $INSILENTMODE -eq 0 ]; then
	read -e INDEX;
else
	INDEX=$INSILENTMODE;
fi

if [ $INDEX -eq 0 ]; then
	echo Canceled!
	exit 1
fi


if [ $INDEX -lt 0 ]; then
	if [ $INDEX -eq -1 ]; then
		echo Starting unmounting of all directories!
	else
		echo Starting forced unmounting of all directories!
		killall -s 5 sshfs >/dev/null 2>&1
	fi
	INDEX=1
	ENDOFINDEX=${#dirs[@]};
else
	ENDOFINDEX=INDEX;
fi


for ((i=$INDEX;i<=$ENDOFINDEX;i++))
do
	echo -e "Unmounting ${dirs[$i]}..."
	fusermount -u ${dirs[$i]}
	echo -e "Removing ${dirs[$i]}..."
	rmdir ${dirs[$i]}
done

echo Done!
