#!/bin/bash

## Set variables
    localdir="/var/local/temp/mountusbdrive/usbdrive";
    disk="/dev/sdc1";
    diskname="1tbencryptedusb";

echo -e -n "\n\nIs the external disk encrypted? [y/n] ";

read answer;
if [ $answer == "y" ]; then

    ## Tell the user to disk and encrypt the drive in Gnome.
        echo -e -n "\n\nBefore you begin, encrypt the drive in Gnome.\n\n";
        echo -e -n "Begin with the drive unpartitioned. Patition it and format it in the Disks utility.\n\n";
        echo -e -n "Be sure to select 'Password protect volume (LUKS)' when you partiton and format it.\n\n";
        echo -e -n "After you have partitoned and formatted it, plug it into this Ubuntu server and do an 'lsblk -f' or 'ls -l /dev | grep sd'.\n\n";
        echo -e -n "Identify the encrypted drive. For example, /dev/sdc1, and set the disk variable in this script. \n\n";
        echo -e -n "Don't forget to set the localdir and diskname variables too.\n\n";
        echo -e -n "Make sure you are root and press ENTER if and when you are ready.\n\n";
        read pause;

    # ## Set the disk variable;
    #     if [ "$disk" == "" ]; then
    #         ls -l /dev | grep disk;
    #         echo -e -n "\n\nType the name of the disk to encrypt. For example, /dev/sdb: ";
    #         read disk;
    #     fi

    # ## Set the localdir variable;
    #     if [ "$localdir" == "" ]; then
    #         echo -e -n ".\n\nOn what directory do you want to mount the encrypted drive. For example, /var/local/externaldisk/flashdrve ";
    #         read localdir;
    #     fi

    # ## Set the diskname variable;
    #     if [ "$diskname" == "" ]; then
    #         echo -e -n ".\n\nWhat do you want to name the USB drive in /dev/mapper.";
    #         echo -e -n "For example, if you write 'encrypted_usb' it will show up as /dev/mapper/encrypted_usb ";
    #         read diskname;
    #     fi

    ## Remove the key file if it exists
        if [ -f "/root/externaldisk.key" ]; then
            rm /root/externaldisk.key;
        fi

    ## if the drive is mounted in /dev/mapper then close it.
        if [ -L "/dev/mapper/$diskname" ]; then
            cryptsetup close $diskname
        fi

    ## Make $localdir if it does not exist
        if [ ! -d $localdir ]; then
            mkdir -p $localdir;
        fi

    ## Install cryptosetup;
        apt install cryptsetup

    ## Get the disk uuid
        diskuuid=`blkid -s UUID -o value $disk`;

    ## Create a key file
        dd if=/dev/urandom of=/root/externaldisk.key bs=4096 count=1

    ## Set permission on the key file
        chmod 600 /root/externaldisk.key

    ## Add key file to LUKS
        cryptsetup luksAddKey $disk /root/externaldisk.key

    ## Add entry into Crypttab
        echo "$diskname UUID=$diskuuid /root/externaldisk.key luks" >> /etc/crypttab

    ## Unlock it manually once
        cryptsetup open $disk $diskname

    ## Get the encrypteduuid
        encrypteduuid=`blkid -s UUID -o value /dev/mapper/$diskname`;

    ## Put entry in /etc/fstab
        echo "UUID=$encrypteduuid $localdir ext4 defaults,nofail 0 2" >> /etc/fstab;

    ## Tell the user to reboot and check it
        echo -e -n "Reboot this machine and check $localdir to make sure the disk is mounted.";

else

    ## Ask user if the want to continue
        echo -e -n "\n\nRUN THIS SCRIPT AS ROOT!\n\n";
        echo -e -n "Your disk value is $disk and your localdir value is $localdir \n\n";
        echo -e -n "Beware $disk will be erased, partitioned, and formatted. \n\n";
        echo -e -n "The output of 'ls -l /dev | grep disk' is: \n\n";
        ls -l /dev | grep disk;

        echo -e -n "\n\nPress ENTER to continue or ctrl + c to exit. ";
        read pause;
        
    ## Check if the localdir exists and create it if it does not.
        if [ ! -d $localdir ]; then
            mkdir -p $localdir;
        fi

    ## Remove existing disks
        wipefs -a $disk;

    ## Partition the disk
        printf "n\np\n1\n\n\nw\n" | fdisk $disk;

    ## Create file system
        mkfs -t ext4 $disk;

    ## Mount the disk
        mount $disk $localdir;

    ## Add disk to /etc/fstab
        uuid=`blkid -s UUID -o value $disk`;
        echo "UUID=$uuid $localdir ext4 defaults 0 0" >> /etc/fstab;

    ## Ask user if they want to reboot
        echo -n -e "\n\nAll done. Reboot [y|n]? ";
        read reboot;
        if [ "$reboot" == "y" ]; then
            shutdown -r now;
        fi
fi