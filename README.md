Quick bash scripts for un/mounting drives using sshfs.
------------------------------------------------------

Dependencies:

*  sshfs
*  fusemount
*  nohup + (thunar or nautilus or dolphin or nemo or open for Mac OS) (optional)

To mount drive run:

    bash ./sshfsmount.sh

To mount in silent mode run (useful when you want drives to be mounted at startup; also the RSA key should have already been saved):

    bash ./sshfsmount.sh --silent [PASSWORD_OF_THE_MACHINE] [USERNAME] [ADDRESS_OF_THE_MACHINE] [[PORT]]

To mount in semi-silent mode

	bash ./sshfsmount.sh <username> <machine_ip_address> [<port>]

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

    chmod a+x ./sshfsmount.sh
    chmod a+x ./sshfsunmount.sh

Installing the tools
--------------------

Although the tools were intended to be used as a separate files you can
install them using the install.sh script.
The installation requires superuser rights.

	su -c "bash ./install.sh"

	or

	sudo bash ./install.sh


Dependencies installation
-------------------------

To install sshfs for Fedora and Cent OS (Red Hat platforms you may need an EPEL repo) use:

    su -

    dnf install fuse-sshfs

        or

    dnf install sshfs

		or

    yum install fuse-sshfs

        or

    yum install sshfs


To install sshfs for Ubuntu (Debian platforms; sometimes sudo is not needed) use:

    sudo apt-get install sshfs
    sudo apt-get install fuse-utils

To install sshfs for Mandriva use:

    urpmi fuse-utils sshfs
