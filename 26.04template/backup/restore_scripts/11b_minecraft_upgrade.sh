#!/bin/bash

## Prompt for variables if not set.
    if [[ -z $standarduser ]]; then
        read -rp $'\n\nWhat is the username of the standard user account? ' standarduser;
    fi

# Set variables
    mcbe_install_dir="/var/local/mcbedrock";

# Change directory
    cd $mcbe_install_dir;

# Ask to check the versions manually
    echo -e -n "\n\nExecute this script as root";
    echo -e -n "\nOn the Microsoft Store click on 'Downloads' in the bottom left and the click 'Check for Updates' to upgrade your client.";
    echo -e -n "\nCheck your client's version and download that version to $mcbe_install_dir/bedrock.zip.";
    echo -e -n "\nCheck /var/local/backup/minecraft_backup_files.csv.";
    echo -e -n "\nPress ENTER to continue.";
    read pause;

# Stop mcbedrock service
    service mcbedrock stop

# Install new version of Minecraft Bedrock
    mv $mcbe_install_dir/mcbedrock_server $mcbe_install_dir/mcbedrock_server.bak
    mkdir $mcbe_install_dir/mcbedrock_server;
    mv $mcbe_install_dir/bedrock.zip $mcbe_install_dir/mcbedrock_server;
    cd $mcbe_install_dir/mcbedrock_server;
    unzip $mcbe_install_dir/mcbedrock_server/bedrock.zip;
    chown -R $standarduser:$standarduser $mcbe_install_dir/mcbedrock_server;

# Restore files and directories
    while IFS="," read -r type oldpath newpath name
    do
    if [ $type == "d" ]; then
        if [ -d "$newpath/$name" ]; then
            rm -rf "$newpath/$name";
        fi
        cp -R "$oldpath/$name" "$newpath";
        chown -R $standarduser:$standarduser "$newpath/$name";

    elif [ $type == "f" ]; then
        cp "$oldpath/$name" $newpath;
        chown $standarduser:$standarduser "$newpath/$name";   
    fi
    done < /var/local/backup/minecraft_backup_files.csv

# Start Minecraft servicer
    service mcbedrock start

# Check the new version works and restart
    echo -e -n "\n\nOpen MCBE and make sure everything works. Press ENTER to remove the mcbedrock_server.bak"; read pause;

# Remove old server
    rm -rf "$mcbe_install_dir/mcbedrock_server.bak";
    rm $mcbe_install_dir/mcbedrock_server/bedrock.zip
