#!/bin/bash
# (C) 27.05.2019 zhgzhg
# semi-silent mode format: sshfsunmount.sh [--unmount <full_path>][-1][-2]
# --unmount <full_path_to_the_directory_to_be_unmounted>
# -1 unmounts all directories inside the default MOUNTPATH
# -2 forced unmount of all inside the default MOUNTPATH

function help()
{
	echo "Format:"
	echo
	echo "Interactive mode:"
	echo "  sshfsunmount"
	echo
	echo "Silent modes:"
	echo "  sshfsunmount --unmount <full_path>"
	echo "  sshfsunmount [<-1> | <-2>]"
	echo
	echo "--unmount <full_path_to_the_directory_to_be_unmounted>"
	echo "-1 unmounts all directories inside the default MOUNTPATH specified in the script"
	echo "-2 forced unmount of all inside the default MOUNTPATH specified in the script"
	echo
	echo " sshfsmount -h | --h | --help     - displays this help"
}

############### configuration #####################

MOUNTPATH="$HOME/sshfsmount"

###################################################

INSILENTMODE=0

if [[ -n "$1" ]]; then
  if [[ "$1" == "-h" || "$1" == "--h" || "$1" == "--help" ]]; then
    help
    exit 0
  fi
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

if [[ ! -d ${MOUNTPATH} ]]; then
  if [[ ${INSILENTMODE} -eq 1 ]]; then
    echo Missing! Check your path and directory name!
  else
    echo Missing! You need to configure MOUNTPATH script variable!
  fi
  exit 1
else
  echo -n "Present! "

  if [[ ${INSILENTMODE} -eq 0 ]]; then
    echo Testing for write permissions...
  else
    echo Write permissions testing is skipped in this mode!
  fi

  TEMPWDIRTEST="write_test_$RANDOM";

  if [[ ${INSILENTMODE} -eq 0 ]]; then
    mkdir $MOUNTPATH/$TEMPWDIRTEST >/dev/null 2>&1
    RETCODE=$?
  else
    RETCODE=0
  fi

  if [[ ${RETCODE} -ne 0 ]]; then
    echo Fail! You do not have write permissions in $MOUNTPATH !
    if [[ "$(id -u)" != "0" ]]; then
        echo [Try to run this script as root!]
    fi
    exit 1
  else
    echo Success!
    rmdir "${MOUNTPATH}/${TEMPWDIRTEST}" >/dev/null 2>&1
  fi
fi

# check if this is Mac OS
uname -a | grep "Darwin" >/dev/null
ISNOTMACOS=$?

# check for available sshfs and fusermount executable

typeset FUSERMOUNT

sshfs -h >/dev/null 2>&1
RETCODE=$?

if [[ ${ISNOTMACOS} -eq 1 ]]; then
  FUSERMOUNT="fusermount"

  if [[ ${RETCODE} -ne 127 ]]; then
    $FUSERMOUNT -h >/dev/null 2>&1
    RETCODE=$?

    if [[ ${RETCODE} -eq 127 ]]; then
      FUSERMOUNT="fusermount3"
      $FUSERMOUNT -h >/dev/null 2>&1
      RETCODE=$?
    fi
  fi
fi

if [[ ${RETCODE} -eq 127 ]]; then
  echo -e "You need to install sshfs!";
  echo -e "For Fedora under root run \"dnf install sshfs\" and \"dnf install fuse-sshfs\".";
  echo -e "For Ubuntu run \"sudo apt-get install sshfs\" and \"sudo apt-get install fuse-utils\".";
  echo -e "For Mandriva run \"urpmi fuse-utils sshfs\".";
  exit 1
fi

declare -a dirs
i=1
if [[ ${INSILENTMODE} -ne 1 ]]; then
  for d in ${MOUNTPATH}/*
  do
    dirs[i++]="${d%/}"
  done

  if [[ "${dirs[1]}" == "$MOUNTPATH/*" ]]; then
    echo -e "\nNo available directories inside $MOUNTPATH !"
    exit 1
  fi
else
  dirs[i++]="$MOUNTPATH"
fi

if [[ ${INSILENTMODE} -eq 0 ]]; then
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

if [[ ${INSILENTMODE} -eq 0 ]]; then
  read -e INDEX;
else
  INDEX=${INSILENTMODE};
fi

if [[ ${INDEX} -eq 0 ]]; then
  echo Canceled!
  exit 1
fi


if [[ ${INDEX} -lt 0 ]]; then
  if [[ ${INDEX} -eq -1 ]]; then
    echo Starting unmounting of all directories!
  else
    echo Starting forced unmounting of all directories!
    killall -s 5 sshfs >/dev/null 2>&1
  fi
  INDEX=1
  ENDOFINDEX=${#dirs[@]};
else
  ENDOFINDEX=${INDEX};
fi


for ((i=$INDEX;i<=$ENDOFINDEX;i++))
do
  echo -e "Unmounting ${dirs[$i]}..."
  if [[ ${ISNOTMACOS} -eq 1 ]]; then
    $FUSERMOUNT -u ${dirs[$i]}
  else
    umount ${dirs[$i]}
  fi
  echo -e "Removing ${dirs[$i]}..."
  rmdir ${dirs[$i]}
done

echo Done!
