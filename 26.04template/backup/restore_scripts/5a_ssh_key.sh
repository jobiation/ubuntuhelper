#!/bin/bash

## Prompt for variables if not set.
    if [[ -z $standarduser ]]; then
        read -rp $'\n\nWhat is the username of the standard user account? ' standarduser;
    fi

# Configure SSH
    read -rp $'\n\nWould you like to create an SSH key that can be used in Windows? [y/n] ' answer;
    if [ $answer == "y" ]; then
        
        sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config;

        SSH_USER_HOME="/home/$standarduser"
        SSH_DIR="$SSH_USER_HOME/.ssh"

        TEMP_KEY="/tmp/temp_ssh_key"
        PPK_FILE="/var/local/mykey.ppk"
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"

        read -rp $'\n\nWould you like your SSH key to have a password? [y/n] ' answer;
        if [ $answer == "y" ]; then
            ssh-keygen -t ed25519 -f "$TEMP_KEY";
        else
            ssh-keygen -t ed25519 -f "$TEMP_KEY" -N "";
        fi

        cat "${TEMP_KEY}.pub" >> "$SSH_DIR/authorized_keys";
        chmod 600 "$SSH_DIR/authorized_keys";
        chown -R $standarduser:$standarduser "$SSH_DIR";
        puttygen "$TEMP_KEY" -O private -o "$PPK_FILE";
        chmod 600 "$PPK_FILE";
        chown $standarduser:$standarduser "$PPK_FILE";
        rm -f "$TEMP_KEY" "${TEMP_KEY}.pub";

        echo -e -n "\n\nYour new key is located at /var/local/mykey.ppk\n\n";

    fi
