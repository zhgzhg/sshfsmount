#!/bin/bash
# versiq 3 (15-16.08.2013)
# silent mode format: sh ./sshfsmount.sh --silent password username machine_ip_address

IPADDRESS="192.168.36.98"
IP=""
USERNAME="root"
USERNM=""
PASSWORD=""

INSILENTMODE=0

if [ "$(id -u)" != "0" ]; then
   echo [You need to run this as root!]
   exit 1
fi

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
fi

typeset RETCODE

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


echo -e "Checking for /mnt/VM_$IPADDRESS...";

if [ ! -d /mnt/VM_$IPADDRESS ]; then
	echo Missing! Creating one...	
	mkdir /mnt/VM_$IPADDRESS
else
	echo Presented!
fi

echo Mounting...

if [ "$PASSWORD" == "" ]; then
	sshfs $USERNAME@$IPADDRESS:/ /mnt/VM_$IPADDRESS/ -C
else
	bash -c "echo $PASSWORD | sshfs $USERNAME@$IPADDRESS:/ /mnt/VM_$IPADDRESS/ -C -o password_stdin"
fi
RETCODE=$?

if [[ "$RETCODE" -ge "0" && "$RETCODE" -le "1" ]]; then
	ANS="";
	echo -e "Should be mounted under /mnt/VM_$IPADDRESS";
	
# check if nohup is presented

	nohup --help >&/dev/null
	RETCODE=$?

	if [[ "$FAVOURITEFILEMANAGER" != "your favourite file manager" && "$INSILENTMODE" != "1" ]]; then
	
		while [[ "$ANS" != "Y" && "$ANS" != "y" && "$ANS" != "N" && "$ANS" != "n" ]]; do
			echo -ne "Do you want to open it with $FAVOURITEFILEMANAGER (only in root mode possible)[Y/N]? ";
			read -e ANS;
		done

		if [[ "$ANS" == "Y" || "$ANS" == "y" ]]; then
			
			if [ "$RETCODE" != "127" ]; then
				FAVOURITEFILEMANAGERCMD="${FAVOURITEFILEMANAGER} /mnt/VM_$IPADDRESS";
				nohup bash -c "$FAVOURITEFILEMANAGERCMD &"
				rm nohup.out >&/dev/null
			else
				$FAVOURITEFILEMANAGER /mnt/VM_$IPADDRESS
			fi
		else
			echo Autoopen canceled!
		fi
	else
		echo -e "To open it run under root use $FAVOURITEFILEMANAGER."
	fi
fi
