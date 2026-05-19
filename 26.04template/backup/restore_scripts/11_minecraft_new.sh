#!/bin/bash

## Prompt for variables if not set.
    if [[ -z $standarduser ]]; then
        read -rp $'\n\nWhat is the username of the standard user account? ' standarduser;
    fi

## Prompt the user to create a new MCBE server.
    echo -e -n "\n\nWould you like to install a new Minecraft Bedrock server? [y/n] ";read answer;
    if [ $answer == "y" ]; then

        ## Prompt the user to download the install file.
            echo -e -n "\n\nRun this script as root.";
            echo -e -n "\nYou can download the Bedrock Server install file at https://www.minecraft.net/en-us/download/server/bedrock";
            echo -e -n "\nSave the install file to /var/local/bedrock.zip.";
            echo -e -n "\nThe Bedrock server will be installed at $mcbe_install_dir/mcbedrock_server and run as $standarduser.";
            echo -e -n "\nPress ENTER when ready.";read pause;

        ## Install unzip
            apt install unzip;

        ## Open port 19132 on the firewall
            ufw allow 19132

        ## Create a variable for the install directory
            mcbe_install_dir="/var/local/mcbedrock";

        ## Create the installfile variable
            installfile="/var/local/bedrock.zip";
            chown $standarduser:$standarduser $installfile;

        ## Make the install directory
            sudo -u $standarduser mkdir -p $mcbe_install_dir/mcbedrock_server;
            cd $mcbe_install_dir/mcbedrock_server;

        ## Move the install file to the install directory and change permissions.
            mv $installfile $mcbe_install_dir/mcbedrock_server;
            chown $standarduser:$standarduser $mcbe_install_dir/mcbedrock_server/bedrock.zip;

        ## Unzip the install files
            sudo -u $standarduser unzip $mcbe_install_dir/mcbedrock_server/bedrock.zip;

        ## Make minecraft.service file
            echo -e -n "[Unit]\n" > "/etc/systemd/system/mcbedrock.service";
            echo -e -n "Description=Minecraft Bedrock Server\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "After=network-online.target\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "Wants=network-online.target\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "[Service]\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "User=$standarduser\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "Group=$standarduser\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "WorkingDirectory=$mcbe_install_dir/mcbedrock_server\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "Environment=\"LD_LIBRARY_PATH=$mcbe_install_dir/mcbedrock_server\"\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "ExecStart=$mcbe_install_dir/mcbedrock_server/bedrock_server\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "ExecStop=/bin/kill -SIGINT $MAINPID\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "Restart=on-failure\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "RestartSec=5\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "StandardOutput=append:$mcbe_install_dir/mcbedrock.log\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "StandardError=append:$mcbe_install_dir/mcbedrock.log\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "[Install]\n" >> "/etc/systemd/system/mcbedrock.service";
            echo -e -n "WantedBy=multi-user.target\n" >> "/etc/systemd/system/mcbedrock.service";

        ## Make manual run script
            echo -e -n "#!/bin/bash\n" > $mcbe_install_dir/mcbedrock_server/run_manually_as_root.sh;
            echo -e -n "service mcbedrock stop\n" >> $mcbe_install_dir/mcbedrock_server/run_manually_as_root.sh;
            echo -e -n "LD_LIBRARY_PATH=$mcbe_install_dir/mcbedrock_server/mcbedrock_server $mcbe_install_dir/mcbedrock_server/bedrock_server\n" >> $mcbe_install_dir/run_manually_as_root.sh;
            chown $standarduser:$standarduser $mcbe_install_dir/mcbedrock_server/run_manually_as_root.sh;  
            chmod 700 $mcbe_install_dir/mcbedrock_server/run_manually_as_root.sh;

        ## Start the mcbedrock service
            systemctl daemon-reload
            systemctl enable mcbedrock
            systemctl restart mcbedrock

        ## Ask user if they want to remove the install file
            echo -e -n "\n\nWould you like to remove the install file $mcbe_install_dir/mcbedrock_server/bedrock.zip? [y/n] ";read answer;
            if [ $answer == "y" ]; then
                rm $mcbe_install_dir/mcbedrock_server/bedrock.zip;
            fi

        # ## Ask the user if they want to copy scripts from the ubuntuhelper directory
        #     echo -e -n "\n\nWould you like to copy scripts from /root/ubuntuhelper/26.04template/scripts/minecraft directory to $mcbe_install_dir?";read answer;
        #     if [ $answer == "y" ]; then
        #         cp /root/ubuntuhelper/26.04template/scripts/minecraft/* $mcbe_install_dir;
        #         chown -R $standarduser:$standarduser $mcbe_install_dir;
        #     fi
    fi
