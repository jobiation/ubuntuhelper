#!/bin/bash

## Prompt for variables if not set.
    if [[ -z $standarduser ]]; then
        read -rp "What is the username of the account for which you want to set a Samba password? " standarduser;
    fi

## Install HTAccess
    echo -e "\nWould you like to create an HTAccess directory? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then
        echo -e "\nWhat is the path to the directory that you want to protect? Example: /var/www/private";
        read htpath;
        echo -e "\nWhat do you want to use for htpassword file name? Example: htpasswd ";
        read htfile;
        echo -e "\nWhat do you want to use for a username? ";
        read htuser;
        
        mkdir -p $htpath;
        chmod 755 $htpath;
        chown $standarduser:$standarduser $htpath;

        htpasswd -c /var/cons/$htfile $htuser;
        chmod 640 /var/cons/$htfile;
        chown $standarduser:www-data /var/cons/$htfile;

        echo -e "AuthName 'Private'" > $htpath/.htaccess;
        echo -e "AuthType Basic" >> $htpath/.htaccess;
        echo -e "AuthUserFile /var/cons/$htfile" >> $htpath/.htaccess;
        echo -e "require valid-user" >> $htpath/.htaccess;
        chmod 640 $htpath/.htaccess;
        chown $standarduser:www-data $htpath/.htaccess;

        echo -e "\n<Directory $htpath>" >> /etc/apache2/apache2.conf;
        echo -e "        Options Indexes FollowSymLinks" >> /etc/apache2/apache2.conf;
        echo -e "        AllowOverride All" >> /etc/apache2/apache2.conf;
        echo -e "        Require all granted" >> /etc/apache2/apache2.conf;
        echo -e "</Directory>" >> /etc/apache2/apache2.conf;

        service apache2 restart;
    fi