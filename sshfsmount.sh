#!/bin/bash
# (C) 21.08.2013 zhgzhg
# silent mode format: sh ./sshfsmount.sh --silent password username machine_ip_address

############### configuration #####################

IPADDRESS="192.168.36.98"
USERNAME="root"
MOUNTPATH="$HOME/sshfsmount"

###################################################

IP=""
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

	mkdir $MOUNTPATH >&/dev/null
	RETCODE=$?
	
	if [ $RETCODE != 0 ]; then
	
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
mkdir $MOUNTPATH/$TEMPWDIRTEST >&/dev/null
RETCODE=$?

if [ $RETCODE != 0 ]; then
	echo Fail! You do not have write permissions in $MOUNTPATH !
	if [ "$(id -u)" != "0" ]; then
			echo [Try to run this script as root!]
	fi	
	exit 1
else
	echo Success!
	rmdir $MOUNTPATH/$TEMPWDIRTEST >&/dev/null
fi

# check for available sshfs executable

sshfs -h >&/dev/null
RETCODE=$?

if [ $RETCODE == 127 ]; then
	echo -e "You need to install sshfs!";
	echo -e "For Fedora under root run \"yum install sshfs\" and \"yum install fuse-sshfs\".";
	exit 1
fi

#check for available file managers

FAVOURITEFILEMANAGER="your favourite file manager"

thunar -h >&/dev/null
RETCODE=$?

if [ $RETCODE == 127 ]; then
	nautilus -h >&/dev/null
	RETCODE=$?
	
	if [ $RETCODE == 127 ]; then
		dolphin -h >&/dev/null
		RETCODE=$?
		
		if [ $RETCODE != 127 ]; then		
			FAVOURITEFILEMANAGER="dolphin"
		fi
	else
		FAVOURITEFILEMANAGER="nautilus"
	fi
else
	FAVOURITEFILEMANAGER="thunar"
fi

echo -ne "\n"


if [[ "$INSILENTMODE" != "1" && "$IP" == "" ]]; then

	echo -ne "IP Address (default $IPADDRESS): ";
	read -e IP;	
fi

if [ -n "$IP" ]; then
	echo -e "Set machine IP address => $IP";
	IPADDRESS=$IP;
else
	echo -e "Set machine IP address => $IPADDRESS";
fi

if [[ "$INSILENTMODE" != "1" && "$USERNM" == "" ]]; then
	echo -ne "Username (default $USERNAME): ";
	read -e USERNM;
fi

if [ -n "$USERNM" ]; then
	echo -e "Set username => $USERNM";
	USERNAME=$USERNM;
else
	echo -e "Set username => $USERNAME";
fi


echo -e "Checking for $MOUNTPATH/VM_$IPADDRESS...";

if [ ! -d $MOUNTPATH/VM_$IPADDRESS ]; then
	echo Missing! Creating one...	
	mkdir $MOUNTPATH/VM_$IPADDRESS
else
	echo Presented!
fi

echo Mounting...

if [ "$PASSWORD" == "" ]; then
	sshfs $USERNAME@$IPADDRESS:/ $MOUNTPATH/VM_$IPADDRESS/ -C
else
	bash -c "echo $PASSWORD | sshfs $USERNAME@$IPADDRESS:/ $MOUNTPATH/VM_$IPADDRESS/ -C -o password_stdin"
fi
RETCODE=$?

if [[ "$RETCODE" -ge "0" && "$RETCODE" -le "1" ]]; then
	ANS="";
	echo -e "\nShould be mounted under $MOUNTPATH/VM_$IPADDRESS";
	
# check if nohup is presented

	nohup --help >&/dev/null
	RETCODE=$?

	if [[ "$FAVOURITEFILEMANAGER" != "your favourite file manager" && "$INSILENTMODE" != "1" ]]; then
	
		while [[ "$ANS" != "Y" && "$ANS" != "y" && "$ANS" != "N" && "$ANS" != "n" ]]; do
			echo -ne "Do you want to open it with $FAVOURITEFILEMANAGER[Y/N]? ";
			read -e -n1 ANS;
		done

		if [[ "$ANS" == "Y" || "$ANS" == "y" ]]; then
			
			if [ "$RETCODE" != "127" ]; then
				FAVOURITEFILEMANAGERCMD="${FAVOURITEFILEMANAGER} $MOUNTPATH/VM_$IPADDRESS";
				nohup bash -c "$FAVOURITEFILEMANAGERCMD &" >&/dev/null
				rm nohup.out >&/dev/null
			else
				$FAVOURITEFILEMANAGER $MOUNTPATH/VM_$IPADDRESS
			fi
		else
			echo Autoopen canceled!
		fi
	else
		echo -e "To open it run use $FAVOURITEFILEMANAGER."
	fi
fi
