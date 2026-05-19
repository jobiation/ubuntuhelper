#!/bin/bash

## Prompt for variables if not set.
    if [[ -z $standarduser ]]; then
        read -rp $'\n\nWhat is the username of the standard user account? ' standarduser;
    fi

## Prompt the user to restore a MCBE server
    echo -e -n "\n\nWould you like to restore the world and important files from another server? [y/n] ";read answer;
    if [ $answer == "y" ]; then

        echo -e -n "\n\nRename the mcbedrock_server directory of the server to be restored to mcbedrock_server.bak.";
        echo -e -n "\nPlace it along side the current mcbedrock_server directory.";
        echo -e -n "\nIn the $mcbe_install_dir directory you should have two subdirectories: mcbecrock_server and mcbedrock_server.bak.";
        echo -e -n "\nCheck /var/local/backup/minecraft_backup_files.csv.";
        echo -e -n "\nPress ENTER when ready.";

        # Stop MCBE service
            service mcbedrock stop

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
            done < "/var/local/backup/backup_files.csv"

        # Start Minecraft servicer
            service mcbedrock start

        # Check the new version works and restart
            echo -e -n "\n\nOpen MCBE and make sure everything works. Press ENTER to remove the mcbedrock_server.bak"; read pause;

        # Remove old server and install file
            rm -rf "$mcbe_install_dir/mcbedrock_server.bak";
    fi