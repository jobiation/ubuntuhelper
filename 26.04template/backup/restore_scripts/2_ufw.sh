#!/bin/bash

    echo -e "\nAre there any ports to open on UFW? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then
        echo -e "\nSpecify a space delimited list of ports. Example 65022 65080 65443";
        read ports;
        portsArr=(${ports})
        for port in "${portsArr[@]}"
            do
                ufw allow $port;
            done
    fi