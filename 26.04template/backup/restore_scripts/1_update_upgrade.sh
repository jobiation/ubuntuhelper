#!/bin/bash

# Start with an apt-get update and upgrade
    echo -e "\nStart with an update and upgrade? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then
        apt-get -y update;
        apt-get -y upgrade;
    fi