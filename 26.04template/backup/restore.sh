#!/bin/bash

# Set variables
    standarduser="tony";
    phpversion="8.5";

# Make user read notes
    echo -e "\n--- Make sure all CSV files read by this script have a trailing LF"
    echo -e "--- If you will be mounting an external disk that is not yet partitioned and formatted, exit this script and use fdisk to partiton and 'mkfs -t ext4 /var/local/externaldisk' to partition.";
    echo -e "--- Look over all files in the root of this backup and set options before deploying this script.";
    echo -e "--- Make sure to run this script a root.";
    echo -e "\nThe standard user variable value is '$standarduser' and PHP is $phpversion. Continue? [y/n] ";
    echo -e "\nPress any key to continue.";
    read pause;

# # Execute commands in precommands.csv
#     echo -e "\nExecute commands in precommands.csv [y/n] ";
#     read answer;
#     if [ $answer == "y" ]; then
#         while read -r command
#         do
#             echo -e "#/bin/bash" > temp.sh;
#             echo -e $command >> temp.sh;
#             chmod 770 temp.sh;
#             source ./temp.sh;
#             rm temp.sh;
#         done < precommands.csv
#     fi

# # Create important directories
#     echo -e "\nCreate the directories listed in important_dir.csv? [y/n] ";
#     read answer;
#     if [ $answer == "y" ]; then
#         while IFS="," read -r path permission owner
#         do
#             mkdir -p $path;
#             chmod -R $permission $path;
#             chown -R $owner $path; 
#         done < important_dir.csv
#     fi

# ## Apt update and upgrade
#     source ./restore_scripts/1_update_upgrade.sh;

# # Open UFW ports
#     source ./restore_scripts/2_ufw.sh;

# # Create another user and make sudoer if desired
#     source ./restore_scripts/3_new_unix_user.sh;

# # Mount external disk at startup
#     source ./restore_scripts/4_mount_external_disk.sh;

# # Configure SSH
#     source ./restore_scripts/5_config_ssh.sh;

# # Install SSH Key
#     source ./restore_scripts/5a_ssh_key.sh;

# # Install Samba
#     source ./restore_scripts/6_samba_install.sh;

# # Install LAMP stack
#     source ./restore_scripts/7_lamp_install.sh;

# Restore files and directories
    echo -e -n "\nRestore files and directories specified in backup_files.csv? [y/n] ";
    echo -e -n "\nType n if this is a new install rather than the restore of a backup.";
    read answer;
    if [ $answer == "y" ]; then
        while IFS="," read -r type path name permission owner altname
        do
            if [ $type == "d" ]; then
                cp -R "../$altname" "$path";
                if [[ "$altname" != "" ]]; then
                    mv "$path/$altname" "$path/$name"; 
                fi
                chown -R $owner "$path/$name";
                permissionArr=(${permission});
                find "$path/$name" -type d -print0 | xargs -I {} -0 chmod "0${permissionArr[0]}" {}
                find "$path/$name" -type f -print0 | xargs -I {} -0 chmod "0${permissionArr[1]}" {}

            elif [ $type == "f" ]; then
                cp "../$altname" $path;
                if [[ "$altname" != "" ]]; then
                    mv "$path/$altname" "$path/$name"; 
                fi
                chmod $permission "$path/$name";
                chown $owner "$path/$name";   
            fi
        done < backup_files.csv
    fi

exit;

# Restore file permissions
    echo -e "\nRestore file permissions specified in file_permissions.csv? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then
        while IFS="," read -r path permission owner
        do
            chown $owner $path;
            chmod $permission $path;
        done < file_permissions.csv
    fi

# Restore crontabs
    echo -e "\nRestore crontabs specified in crontabs.csv? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then
        while read -r user
        do
            crontab -u $user "../crontab/crontab_$user.txt";
        done < crontabs.csv
    fi

# Restart Services
    source ./restore_scripts/8_services_restart.sh;

# Install MUTT
    source ./restore_scripts/9_mutt_install.sh;

# Execute commands in postcommands.csv
    echo -e "\nExecute commands in postcommands.csv? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then
        while read -r command
        do
            echo -e "#/bin/bash" > temp.sh;
            echo -e $command >> temp.sh;
            chmod 770 temp.sh;
            source ./temp.sh;
            rm temp.sh;
        done < postcommands.csv
    fi

#Create an HTAccess Directory
    source ./restore_scripts/10_htaccess_setup.sh;

# Remove history
    history -c && history -w;
    unset HISTFILE;
    rm /root/.bash_history;

# Final Notes
    echo -e "\n..............................FINAL NOTES................";
    echo -e "--- Test MUTT and the connection to the DB for PHP, Python, and BASH.";
    echo -e "--- Test the database connection at http://ipaddress/misc/testdb.php";
    echo -e "--- Make sure the database is backing up and time is correct.";
    echo -e "--- Get the /var/local/externaldisk/remotebackup folder backing up offsite.";
    
# Restart the server
    echo -e "\nYou might need to restart this server for some setting to take affect. Restart? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then
        shutdown -r now;
    fi


## OLD CODE

    # echo -e "\nWould you like to mount an already partitioned and formatted external disk at startup? [y/n] ";
    # read answer;
    # if [ $answer == "y" ]; then
    #     echo -e "\nWhat is the full path of the local directory on which you would like to mount the disk? ";
    #     read localdir;
    #     if [ ! -d "$localdir" ]; then
    #         mkdir -p $localdir;
    #     fi

    #     echo -e "\n";
    #     ls -l /dev | grep disk;
    #     echo -e "\nSee output above. What is the full /dev path to the disk? ";
    #     read devpath;

    #     echo -e "\n";
    #     blkid
    #     echo -e "\nCopy the UUID, without quotes, from the output above and press ENTER: ";
    #     read uuid;

    #     echo "UUID=$uuid $localdir ext4 defaults 0 0" >> /etc/fstab;
    #     echo -e "\nMount it now? [y/n] ";
    #     read answer;
    #     if [ $answer == "y" ]; then
    #         mount $devpath $localdir;
    #     fi
    # fi

# Give standard user onwership of /var/local
#     echo -e "\nGive $standarduser ownership of /var/local? [y/n] ";
#     read answer;
#     if [ $answer == "y" ]; then
#         chmod -R 770 /var/local;
#         chown -R $standarduser:$standarduser /var/local;
#     fi