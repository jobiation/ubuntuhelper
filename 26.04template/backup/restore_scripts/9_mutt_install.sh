#!/bin/bash

    echo -e "\nInstall Mutt? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then
        apt-get -y install mutt;

        echo -e "\n....................................................................................................................";
        echo -e "\nMUTT will be setup to work with a Gmail account. If you are using another provider, you can tweak the settings later.";
        echo -e "\nType the portion of the sending gmail address before the @. In other words, do not write the @gmail.com part.";
        read sender_email;

        echo -e "\nYou can generate an app specific password at https://myaccount.google.com/apppasswords";
        echo -e "Your app specific password should have no spaces in it.";
        echo -e "You will not see the app sepecific password as you type it or paste it.";
        echo -e "What is the app specific password? ";

        read -s sender_app_pass;

        echo -e "\nWhat is the sender's display name?";
        read sender_display_name;

        echo -e "\nWhat is the name of the unix user who will be sending emails? Example: tony";
        read unix_emailer;
        echo -e "\nWhat is the name of the unix group that will be sending emails? Recommended: www-data";
        read unix_group;
        echo -e "\nWhat is the MUTT home directory? Recommended: /var/cons";
        read mutthome;

        echo "set ssl_force_tls=yes" > "$mutthome/muttrc";
        echo "set realname='$sender_display_name'" >> "$mutthome/muttrc";
        echo "set from='$sender_email@gmail.com'" >> "$mutthome/muttrc";
        echo "set smtp_url='smtps://$sender_email@smtp.gmail.com'" >> "$mutthome/muttrc";
        echo "set smtp_pass='$sender_app_pass'" >> "$mutthome/muttrc";

        chmod 660 "$mutthome/muttrc";
        chown $unix_emailer:$unix_group "$mutthome/muttrc";
    
        echo "echo \"\$3\" | /usr/bin/mutt -s \"\$2\" -F $mutthome/muttrc \"\$1\"" > $mutthome/muttsend.sh;
        echo -e "\n";
        echo -e "# To use this script from BASH, type $mutthome/muttsend.sh recipeint@gmail.com 'subject' 'body'" >> $mutthome/muttsend.sh;
        echo -e "# For example: sudo -u tony $mutthome/muttsend.sh tony@me.com 'Test Submect' 'Test message.'" >> $mutthome/muttsend.sh;
        
        chmod 770 $mutthome/muttsend.sh;
        chown $unix_emailer:$unix_group $mutthome/muttsend.sh;

        echo -e "\nA script for sending email was placed in $mutthome/muttsend.sh";
        echo -e "Nano the script for instructions on how to use.";

        echo -e "\nSend a test email? [y/n]";
        read answer;
        if [ $answer == "y" ]; then
            echo -e "\nWhat address should receive the email?";
            read recipient;
            sudo -u $unix_emailer $mutthome/muttsend.sh "$recipient" "Test from muttsend.sh" "It worked";
        fi
        echo -e "\nLook at the code of this script for information on how to use MUTT with PHP and Python.";
    fi

##### Using the muttsend.sh script via PHP
    # <?php
    # echo "You must execute this script as the user for whom MUTT was configured.";
    # $notify_script = "/var/cons/muttsend.sh";
    # $notify_recipients = "me@yahoo.com";
    # $notify_subject = "TheSubject2";
    # $message = "TheBody2";
    # exec("{$notify_script} {$notify_recipients} '{$notify_subject}' '{$message}'");
    # ?>

    ##### Using the muttsend.sh script via Python
    # #!/usr/bin/env python3
    # import subprocess;
    # notify_script = "sudo -u tony /var/cons/muttsend.sh";
    # notify_recipients = "me@gmail.com";
    # notify_subject = "This is the subject.";
    # message = "This is the message";
    # subprocess.call(notify_script+" '"+notify_recipients+"' '"+notify_subject+"' '"+message+"'",shell=True);