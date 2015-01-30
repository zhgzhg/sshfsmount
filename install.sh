#!/bin/bash
# (C) 30.01.2015 zhgzhg
# installation script for sshfsmount and sshfsunmount tools

if [ "$(id -u)" != "0" ]; then
      echo [You need to run this script as root!]
      exit 1
fi

echo -e "\nInstalling sshfsmount project...\n"

echo Copying sshfsmount to /usr/local/bin
cp -f sshfsmount.sh /usr/local/bin/sshfsmount
if [ $? -eq 0 ]; then
  echo Success!
  chmod 755 /usr/local/bin/sshfsmount
else
  echo Fail!
fi

SUCCESS=0

echo Copying sshfsunmount to /usr/local/bin
cp -f sshfsunmount.sh /usr/local/bin/sshfsunmount
if [ $? -eq 0 ]; then
  echo Success!
  chmod 755 /usr/local/bin/sshfsunmount
  SUCCESS=1
else
  echo Fail!
fi

echo -e "\nDone!\n"

if [ $SUCCESS -eq 1 ]; then
  echo Now you can use directly these tools as a commands named
  echo 'sshfsmount' and 'sshfsunmount'.
fi
