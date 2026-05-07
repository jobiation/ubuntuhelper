#!/bin/bash

# Configure SSH
    echo -e "\nWould you like to run SSH on a port other than 22? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then
        echo -e "\nOn what port would you like to run SSH? ";
        read sshport;
        findport="#Port 22";
        replaceport="Port $sshport";

        mv /etc/ssh/sshd_config /etc/ssh/sshd_config.bak;
        touch /etc/ssh/sshd_config;

        while IFS='' read -r line
        do
            if [[ "$line" == *"$findport"* ]]; then
                echo $replaceport >> /etc/ssh/sshd_config;
            else
                echo $line >> /etc/ssh/sshd_config;
            fi 
        done < /etc/ssh/sshd_config.bak
    fi

    echo -e "\nWould you like to restrict SSH to only certain IPs? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then
        echo -e "Specify a comma separated list of IPs and networks that will be able to access this server via ssh. Example: 10.0.1.0/24,10.0.0.4 ";
        read sshpermit;
        echo "sshd: $sshpermit" >> /etc/hosts.allow
        echo "sshd: ALL" >> /etc/hosts.deny
    fi