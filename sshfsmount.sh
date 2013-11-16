#!/bin/bash
# (C) 16.11.2013 zhgzhg
# silent mode format: sshfsmount.sh [--silent password username machine_ip_address port]

############### configuration #####################

IPADDRESS="192.168.36.98"
PORT="22"
USERNAME="root"
MOUNTPATH="$HOME/sshfsmount"

###################################################

IP=""
PRT=""
USERNM=""
PASSWORD=""

INSILENTMODE=0

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
			PORT=$5
		fi
		
		
		if [[ "$USERNM" != "" && "$IP" != "" && "$PASSWORD" != "" ]]; then
			INSILENTMODE=1
		fi
	else
		echo -e "Invalid first argument! (Must be --silent)! See comments inside this script!"
		exit 1
	fi	
fi

typeset RETCODE

# check if mount path exists

echo Checking for $MOUNTPATH ...

if [ ! -d $MOUNTPATH ]; then

	echo Missing! Trying to create it!

	mkdir $MOUNTPATH >/dev/null 2>&1
	RETCODE=$?
	
	if [ $RETCODE -ne 0 ]; then
	
		echo Fail!
		
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
	echo Presented!
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
	echo -e "For Fedora under root run \"yum install sshfs\" and \"yum install fuse-sshfs\".";
	echo -e "For Ubuntu run \"sudo apt-get install fuse-utils sshfs\"."
	echo -e "For Mandriva run \"urpmi fuse-utils sshfs\".";
	exit 1
fi

#check for available file managers

FAVOURITEFILEMANAGER="your favourite file manager"

thunar -h >/dev/null 2>&1
RETCODE=$?

if [ $RETCODE -eq 127 ]; then
	nautilus -h >/dev/null 2>&1
	RETCODE=$?
	
	if [ $RETCODE -eq 127 ]; then
		dolphin -h >/dev/null 2>&1
		RETCODE=$?
		
		if [ $RETCODE -ne 127 ]; then		
			FAVOURITEFILEMANAGER="dolphin"
		fi
	else
		FAVOURITEFILEMANAGER="nautilus"
	fi
else
	FAVOURITEFILEMANAGER="thunar"
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


echo -e "Checking for $MOUNTPATH/VM_${IPADDRESS}_${PORT}_${USERNAME}...";

if [ ! -d $MOUNTPATH/VM_${IPADDRESS}_${PORT}_${USERNAME} ]; then
	echo Missing! Creating one...	
	mkdir $MOUNTPATH/VM_${IPADDRESS}_${PORT}_${USERNAME}
	RETCODE=$?
	if [ $RETCODE -ge 0 ]; then
		echo -e "Error! Cannot create that directory!";
		exit 1;
	fi
else
	echo Presented!
fi

echo Mounting...

if [ "$PASSWORD" = "" ]; then
	sshfs $USERNAME@$IPADDRESS:/ $MOUNTPATH/VM_${IPADDRESS}_${PORT}_${USERNAME}/ -C -p $PORT
else
	bash -c "echo $PASSWORD | sshfs $USERNAME@$IPADDRESS:/ $MOUNTPATH/VM_${IPADDRESS}_${PORT}_${USERNAME}/ -C -p $PORT -o password_stdin"
fi
RETCODE=$?

if [[ $RETCODE -ge 0 && $RETCODE -le 1 ]]; then
	ANS="";
	echo -e "\nShould be mounted under $MOUNTPATH/VM_${IPADDRESS}_${PORT}_${USERNAME}";
	
# check if nohup is presented

	nohup --help >/dev/null 2>&1
	RETCODE=$?

	if [[ "$FAVOURITEFILEMANAGER" != "your favourite file manager" && $INSILENTMODE -ne 1 ]]; then
	
		while [[ "$ANS" != "Y" && "$ANS" != "y" && "$ANS" != "N" && "$ANS" != "n" ]]; do
			echo -ne "Do you want to open it with $FAVOURITEFILEMANAGER[Y/N]? ";
			read -e -n1 ANS;
		done

		if [[ "$ANS" = "Y" || "$ANS" = "y" ]]; then
			
			if [ $RETCODE -ne 127 ]; then
				FAVOURITEFILEMANAGERCMD="${FAVOURITEFILEMANAGER} $MOUNTPATH/VM_$IPADDRESS";
				nohup bash -c "$FAVOURITEFILEMANAGERCMD &" >/dev/null 2>&1
				rm nohup.out >/dev/null 2>&1
			else
				$FAVOURITEFILEMANAGER $MOUNTPATH/VM_${IPADDRESS}_${PORT}_${USERNAME}
			fi
		else
			echo Autoopen canceled!
		fi
	else
		echo -e "To open it run use $FAVOURITEFILEMANAGER."
	fi
fi
