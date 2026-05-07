#!/bin/bash

## Prompt for variables if not set.
    if [[ -z $standarduser ]]; then
        read -rp "What is the username of the account for which you want to set a Samba password? " standarduser;
    fi

# Install Samba
    echo -e "\nInstall Samba? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then

        apt-get -y install samba;

        ufw allow 139;
        ufw allow 445;

        echo -e "\nSet a password for $standarduser: ";
        smbpasswd -a $standarduser;
        
        echo -e "\nWould you like to set a Samba password for another user? [y/n] ";
        read answer;
        if [ $answer == "y" ]; then
            echo -e "\nWhat is the name of the user for which you would like to set a Samba password? ";
            read newsmbpwd;
            smbpasswd -a $newsmbpwd;
        fi

        echo -e "\nWould you like to create Samba shares for /var/www and /var/local? [y/n]";
        read answer;
        if [ $answer == "y" ]; then

            echo -e "\nSpecify a space delimited list of users who can access the shares: ";
            read smbusers;
            echo -e "\nSpecify a space delimited list of hosts and networks that can access the shares. Example: 10.0.1.0/24 10.0.0.4 ";
            read smbhosts;

            echo -e "[local]" >> /etc/samba/smb.conf
            echo -e "  comment = local directory" >> /etc/samba/smb.conf
            echo -e "  browseable = yes" >> /etc/samba/smb.conf
            echo -e "  path = /var/local" >> /etc/samba/smb.conf
            echo -e "  guest ok = no" >> /etc/samba/smb.conf
            echo -e "  read only = no" >> /etc/samba/smb.conf
            echo -e "  create mask = 0660" >> /etc/samba/smb.conf
            echo -e "  directory mask = 0770" >> /etc/samba/smb.conf
            echo -e "  valid users = $smbusers" >> /etc/samba/smb.conf
            echo -e "  hosts allow = $smbhosts" >> /etc/samba/smb.conf

            echo -e "\n[www]" >> /etc/samba/smb.conf
            echo -e "  comment = www directory" >> /etc/samba/smb.conf
            echo -e "  browseable = yes" >> /etc/samba/smb.conf
            echo -e "  path = /var/www" >> /etc/samba/smb.conf
            echo -e "  guest ok = no" >> /etc/samba/smb.conf
            echo -e "  read only = no" >> /etc/samba/smb.conf
            echo -e "  create mask = 0664" >> /etc/samba/smb.conf
            echo -e "  directory mask = 0775" >> /etc/samba/smb.conf
            echo -e "  valid users = $smbusers" >> /etc/samba/smb.conf
            echo -e "  hosts allow = $smbhosts" >> /etc/samba/smb.conf
        fi
    fi