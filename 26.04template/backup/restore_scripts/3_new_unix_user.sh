#!/bin/bash

    echo -e "\nWould you like to create another Unix user? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then
        echo -e "\nWhat is the new user's username? ";
        read newuser;
        mkdir "/home/$newuser";
        useradd -d "/home/$newuser" $newuser;
        chmod 770 "/home/$newuser";
        chown $newuser:$newuser "/home/$newuser";
        passwd $newuser;
        
        echo -e "\nShould $newuser be a sudoer? [y/n] ";
        read answer;
        if [ $answer == "y" ]; then
            usermod -aG sudo $newuser;
        fi
    fi