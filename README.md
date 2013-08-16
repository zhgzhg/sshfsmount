Quick bash scripts for un/mounting drivers using sshfs.

Dependencies:

*	sshfs
*	fusemount
*	nohup + (thunar or nautilus or dolphin) (optional)

To install sshfs for Fedora (Red Hat platforms) and Cent OS use:

	su -

	yum install fuse-sshfs

		or

	yum install sshfs


To install sshfs for Ubuntu (Debian platforms; sometimes sudo is not needed) use:

	sudo apt-get install fuse-utils sshfs

To instsll sshfs for Mandriva use:

	urpmi fuse-utils sshfs


To mount drive run:

	sh ./sshfsmount.sh

To mount in silent mode run (useful when you want drives to be mounted at startup; also the RSA key should have already been saved):

	sh ./sshfsmount.sh --silent PASSWORD_OF_THE_MACHINE USERNAME ADDRESS_OF_THE_MACHINE

To unmount run:

	sh ./sshfsunmount.sh



