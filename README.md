Quick bash scripts for un/mounting drives using sshfs.
------------------------------------------------------

Dependencies:

*	sshfs
*	fusemount
*	nohup + (thunar or nautilus or dolphin) (optional)

To mount drive run:

	bash ./sshfsmount.sh

To mount in silent mode run (useful when you want drives to be mounted at startup; also the RSA key should have already been saved):

	bash ./sshfsmount.sh --silent PASSWORD_OF_THE_MACHINE USERNAME ADDRESS_OF_THE_MACHINE

To unmount run:

	bash ./sshfsunmount.sh
	
To unmount in semi-silent mode run (useful when you want drives to be unmounted at shutdown):

	bash ./sshfsunmount.sh --unmount FULL_DIRECTORY_PATH_TO_UNMOUNT
		or
	bash ./sshfsunmount.sh -1
		or
	bash ./sshfsunmount.sh -2
	
	-1 argument will unmount all the directories inside the default mount path.
	-2 argument will force unmount all the directories inside the default mount path.
	
If you do not want to type "bash" or "sh" before the scripts use:

	chmod +x ./sshfsmount.sh
	chmod +x ./sshfsunmount.sh


Dependencies installation
-------------------------

To install sshfs for Fedora (Red Hat platforms) and Cent OS use:

	su -

	yum install fuse-sshfs

		or

	yum install sshfs


To install sshfs for Ubuntu (Debian platforms; sometimes sudo is not needed) use:

	sudo apt-get install fuse-utils sshfs

To install sshfs for Mandriva use:

	urpmi fuse-utils sshfs
