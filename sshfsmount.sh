#!/bin/bash
# (C) 03.11.2016 zhgzhg
# silent mode format: sshfsmount.sh [--silent password username machine_ip_address port]
# semi-interactive mode format: sshfsmount.sh username machine_ip_address [port]

function help()
{
	echo "Format:"
	echo
	echo "Interactive mode:"
	echo "  sshfsmount"
	echo
	echo "Semi-interactive mode:"
	echo "  sshfsmount <username> <machine_ip_address> [<port>]"
	echo
	echo "Silent mode:"
	echo "  sshfsmount --silent [<password>] [<username>] [<machine_ip_addr>] [[<port>]]"
	echo "Each of the above parameters is required, but optional starting from left to"
	echo "right. Not specifying it will turn off the silent mode and make sshfsmount to"
	echo "ask for it. The only exception makes the port parameter."
	echo
	echo " sshfsmount -h | --h | --help     - displays this help"
}

##### the default configuration suggested during interactive mode #####

IPADDRESS="192.168.36.98"
PORT="22"
USERNAME="root"
MOUNTPATH="$HOME/sshfsmount"
REMOTEMOUNTPATH="/"

#######################################################################

IP=""
PRT=""
USERNM=""
PASSWORD=""

INSILENTMODE=0

if [ -n "$1" ]; then
  if [[ "$1" == "-h" || "$1" == "--h" || "$1" == "--help" ]]; then
    help
    exit 0
  fi
fi


if [ -n "$1" ]; then
  if [ "$1" == "--silent" ]; then

    if [ -n "$2" ]; then
      PASSWORD=$2
    fi
    if [ -n "$3" ]; then
      USERNM=$3
    fi
    if [ -n "$4" ]; then
      IP=$4
    fi
    if [ -n "$5" ]; then
      PRT=$5
    fi


    if [[ "$USERNM" != "" && "$IP" != "" && "$PASSWORD" != "" ]]; then
      INSILENTMODE=1
    fi
  else
    if [[ $# -ge 2  && $# -lt 4 ]]; then
      USERNM=$1
      IP=$2
      if [ -n "$3" ]; then
        PRT=$3
      else
        PRT=$PORT
      fi
    else
      help
      exit 1
    fi
  fi
fi

typeset RETCODE

# check if mount path exists

echo -e "Checking for '${MOUNTPATH}' directory..."

if [ ! -d $MOUNTPATH ]; then

  echo Missing! Trying to create it!

  mkdir $MOUNTPATH >/dev/null 2>&1
  RETCODE=$?

  if [ $RETCODE -ne 0 ]; then

    echo Fail!
    if [[ -f $MOUNTPATH ]]; then
		echo -e "'${MOUNTPATH}' is a file!\nRename it or remove it from there!"
		exit 1
	fi

    if [ "$(id -u)" != "0" ]; then
      echo [You need to run this script as root!]
      exit 1
    else
      echo Cannot create $MOUNTPATH !
      exit 1
    fi
  else
    echo Created!
  fi
else
  echo Present!
fi

echo Testing for write permissions...

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

# check for available sshfs executable

sshfs -h >/dev/null 2>&1
RETCODE=$?

if [ $RETCODE -eq 127 ]; then
  echo -e "You need to install sshfs!";
  echo -e "For Fedora under root run \"dnf install sshfs\" and \"dnf install fuse-sshfs\".";
  echo -e "For Ubuntu run \"sudo apt-get install sshfs\" and \"sudo apt-get install fuse-utils\".";
  echo -e "For Mandriva run \"urpmi fuse-utils sshfs\".";
  exit 1
fi

# check if this is Mac OS
uname -a | grep "Darwin" >/dev/null
ISNOTMACOS=$?

#check for available file managers

FAVOURITEFILEMANAGER="your favourite file manager"

if [ $ISNOTMACOS -eq 1 ]; then

  thunar -h >/dev/null 2>&1
  RETCODE=$?

  if [ $RETCODE -eq 127 ]; then
    nautilus -h >/dev/null 2>&1
    RETCODE=$?

    if [ $RETCODE -eq 127 ]; then
      dolphin -h >/dev/null 2>&1
      RETCODE=$?

      if [ $RETCODE -eq 127 ]; then
        nemo -h >/dev/null 2>&1
        RETCODE=$?

        if [ $RETCODE -ne 127 ]; then
          FAVOURITEFILEMANAGER="nemo"
        fi
      else
        FAVOURITEFILEMANAGER="dolphin"
      fi
    else
      FAVOURITEFILEMANAGER="nautilus"
    fi
  else
    FAVOURITEFILEMANAGER="thunar"
  fi
else
  FAVOURITEFILEMANAGER="open"
fi
echo -ne "\n"


if [[ $INSILENTMODE -ne 1 && "$IP" = "" ]]; then

  echo -e "Hostname/IP Address (default $IPADDRESS): ";
  read -e IP;
  echo -en "\033[1A\033[2K";
fi

if [ -n "$IP" ]; then
  echo -e "Set machine address => $IP";
  IPADDRESS=$IP;
else
  echo -e "Set machine address => $IPADDRESS";
fi

if [[ $INSILENTMODE -ne 1 && "$PRT" = "" ]]; then

  echo -e "Port (default $PORT): ";
  read -e PRT;
  echo -en "\033[1A\033[2K";
fi

if [ -n "$PRT" ]; then
  echo -e "Set machine port => $PRT";
  PORT=$PRT;
else
  echo -e "Set machine port => $PORT";
fi

if [[ $INSILENTMODE -ne 1 && "$USERNM" = "" ]]; then
  echo -e "Username (default $USERNAME): ";
  read -e USERNM;
  echo -en "\033[1A\033[2K";
fi

if [ -n "$USERNM" ]; then
  echo -e "Set username => $USERNM";
  USERNAME=$USERNM;
else
  echo -e "Set username => $USERNAME";
fi

MNT="${MOUNTPATH}/VM_${IPADDRESS}_${PORT}_${USERNAME}"
echo -e "Checking for ${MNT}...";

if [ ! -d "${MNT}" ]; then
  echo Missing! Creating one...
  mkdir "${MNT}"
  RETCODE=$?
  if [ $RETCODE -gt 0 ]; then
    grep -qs "${MNT}" /proc/mounts
    RETCODE=$?
    if [ $RETCODE -eq 0 ]; then
      echo -e "Error! Cannot create that directory!"
      exit 1;
    else
      if [ $ISNOTMACOS -eq 1 ]; then
	    fusermount -u "${MNT}" >/dev/null 2>&1
	  else
	    umount "${MNT}" >/dev/null 2>&1
	  fi
	fi
  fi
else
  echo Present!
  grep -qs "${MNT}" /proc/mounts
  RETCODE=$?
  if [ $RETCODE -eq 0 ]; then
    echo -e "Error! The directory is already mounted!"
    exit 1;
  else
	if [ $ISNOTMACOS -eq 1 ]; then
	  fusermount -u "${MNT}" >/dev/null 2>&1
	else
	  umount "${MNT}" >/dev/null 2>&1
	fi
  fi
fi

echo Mounting...

if [ "$PASSWORD" = "" ]; then
  sshfs $USERNAME@$IPADDRESS:$REMOTEMOUNTPATH ${MNT}/ -C -p $PORT
else
  bash -c "echo $PASSWORD | sshfs $USERNAME@$IPADDRESS:$REMOTEMOUNTPATH ${MNT}/ -C -p $PORT -o password_stdin"
fi
RETCODE=$?

if [[ $RETCODE -ge 0 && $RETCODE -le 1 ]]; then
  ANS="";
  echo -e "\nShould be mounted under ${MNT}";

# check if nohup is present

  nohup --help >/dev/null 2>&1
  RETCODE=$?

  if [[ "$FAVOURITEFILEMANAGER" != "your favourite file manager" && $INSILENTMODE -ne 1 ]]; then

    while [[ "$ANS" != "Y" && "$ANS" != "y" && "$ANS" != "N" && "$ANS" != "n" ]]; do
      echo -ne "Do you want to open it with $FAVOURITEFILEMANAGER[Y/N]? ";
      read -e -n1 ANS;
    done

    if [[ "$ANS" = "Y" || "$ANS" = "y" ]]; then

      if [ $RETCODE -ne 127 ]; then
        FAVOURITEFILEMANAGERCMD="${FAVOURITEFILEMANAGER} \"${MNT}\"";
        nohup bash -c "$FAVOURITEFILEMANAGERCMD &" >/dev/null 2>&1
        rm nohup.out >/dev/null 2>&1
      else
        $FAVOURITEFILEMANAGER "${MNT}"
      fi
    else
      echo Autoopen canceled!
    fi
  else
    echo -e "To open it run use $FAVOURITEFILEMANAGER."
  fi
fi
