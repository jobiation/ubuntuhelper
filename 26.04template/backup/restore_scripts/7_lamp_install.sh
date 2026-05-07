#!/bin/bash

## Prompt for variables if not set.
    if [[ -z $standarduser ]]; then
        read -rp "What is the username of the account for which you want to set a Samba password? " standarduser;
    fi

    if [[ -z $phpversion ]]; then
        read -rp "What is the version of PHP to install? [8.5 for Ubuntu 26.04]: " phpversion;
    fi

# Install Apache
    echo -e "\nInstall Apache? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then
        apt-get -y install apache2;
        a2enmod ssl;
        service apache2 restart;
        a2ensite default-ssl;
        service apache2 restart;
        chown -R $standarduser:$standarduser /var/www;

        mv /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.bak2;
        mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.bak2;

        finddocroot="DocumentRoot /var/www/html";
        replacedocroot="        DocumentRoot /var/www";

        while IFS='' read -r line
        do
            if [[ "$line" == *"$finddocroot"* ]]; then
                echo $replacedocroot >> /etc/apache2/sites-available/default-ssl.conf;
            else
                echo $line >> /etc/apache2/sites-available/default-ssl.conf;
            fi 
        done < /etc/apache2/sites-available/default-ssl.conf.bak2

        while IFS='' read -r line
        do
            if [[ "$line" == *"$finddocroot"* ]]; then
                echo $replacedocroot >> /etc/apache2/sites-available/000-default.conf;
            else
                echo $line >> /etc/apache2/sites-available/000-default.conf;
            fi 
        done < /etc/apache2/sites-available/000-default.conf.bak2

        echo -e "\nWould you like to run HTTP and HTTPS on a ports other than 80 and 443? [y/n] ";
        read answer;
        if [ $answer == "y" ]; then
            echo -e "\nOn what port would you like to run HTTP? ";
            read httpport;
            echo -e "\nOn what port would you like to run HTTPS? ";
            read httpsport;

            mv /etc/apache2/ports.conf /etc/apache2/ports.conf.bak;

            echo -e "Listen $httpport" > /etc/apache2/ports.conf;
            echo -e "<IfModule ssl_module>" >> /etc/apache2/ports.conf;
            echo -e "	Listen $httpsport" >> /etc/apache2/ports.conf;
            echo -e "</IfModule>" >> /etc/apache2/ports.conf;
            echo -e "<IfModule mod_gnutls.c>" >> /etc/apache2/ports.conf;
            echo -e "	Listen $httpsport" >> /etc/apache2/ports.conf;
            echo -e "</IfModule>" >> /etc/apache2/ports.conf;

            mv /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.bak;
            mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.bak;

            findhttp="<VirtualHost *:80>";
            replacehttp="<VirtualHost *:$httpport>";
            findhttps="<VirtualHost *:443>";
            replacehttps="<VirtualHost *:$httpsport>";

            while IFS='' read -r line
            do
                if [[ "$line" == *"$findhttps"* ]]; then
                    echo $replacehttps >> /etc/apache2/sites-available/default-ssl.conf;
                else
                    echo $line >> /etc/apache2/sites-available/default-ssl.conf;
                fi 
            done < /etc/apache2/sites-available/default-ssl.conf.bak

            while IFS='' read -r line
            do
                if [[ "$line" == *"$findhttp"* ]]; then
                    echo $replacehttp >> /etc/apache2/sites-available/000-default.conf;
                else
                    echo $line >> /etc/apache2/sites-available/000-default.conf;
                fi 
            done < /etc/apache2/sites-available/000-default.conf.bak

        fi
    fi

# Generate a self-signed TLS certificate for web traffic
    echo -e "\nGenerate a self-signed TLS certificate for web traffic? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then
        echo -e "\nYou will be prompted for a certificate password, type one even if you don't want one.";
        echo -e "What do you want to name the certificate? Recommendation: mycert: ";
        read certname;
        openssl genrsa -des3 -out $certname.key 4096;
        openssl req -new -key $certname.key -out $certname.csr;
        openssl x509 -req -days 9999 -in $certname.csr -signkey $certname.key -out $certname.crt;
        openssl rsa -in $certname.key -out $certname.key.new;
        mv $certname.key.new $certname.key;
        rm $certname.csr;
        
        mv $certname.crt /etc/ssl/certs;
        mv $certname.key /etc/ssl/private;
        chmod 640 "/etc/ssl/private/$certname.key";
        chgrp ssl-cert "/etc/ssl/private/$certname.key";

        echo -e "\n$certname.cer copied to /etc/ssl/certs.";
        echo -e "$certname.key copied to /etc/ssl/private.";

        echo -e "\nIf default-ssl.conf is at it's defaults referencing the snakeoil certs, this script can update it.";
        echo -e "Change default-ssl.conf to reference the new certificate? [y/n] ";
        read answer;
        if [ $answer == "y" ]; then
            findcert="/etc/ssl/certs/ssl-cert-snakeoil.pem";
            replacecert="	SSLCertificateFile      /etc/ssl/certs/mycert.crt";
            findkey="/etc/ssl/private/ssl-cert-snakeoil.key";
            replacekey="	SSLCertificateKeyFile   /etc/ssl/private/mycert.key";

            mv /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.bak;
            touch /etc/apache2/sites-available/default-ssl.conf;

            while IFS='' read -r line
            do
                if [[ "$line" == *"$findcert"* ]]; then
                    echo $replacecert >> /etc/apache2/sites-available/default-ssl.conf;
                elif [[ "$line" == *"$findkey"* ]]; then
                    echo $replacekey >> /etc/apache2/sites-available/default-ssl.conf;
                else
                    echo $line >> /etc/apache2/sites-available/default-ssl.conf;
                fi 
            done < /etc/apache2/sites-available/default-ssl.conf.bak
        fi

        echo -e "\nOpen /etc/apache2/sites-available/default-ssl.conf to make sure the certificate path is correct? [y/n] ";
        read answer;
        if [ $answer == "y" ]; then
            nano /etc/apache2/sites-available/default-ssl.conf;
        fi

        echo -e "\nRestart Apache? [y/n]";
        read answer;
        if [ $answer == "y" ]; then
            service apache2 restart;
        fi
    fi

# Install PHP
    echo -e "\nInstall PHP? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then
        apt-get -y install php;
        apt-get -y install php$phpversion-ldap;
    fi

    echo -e -n "<!DOCTYPE html>\n";
    echo -e -n "<html>\n";
    echo -e -n "    <head>\n";
    echo -e -n "        <title>Home Page</title>\n";
    echo -e -n "    </head>\n";
    echo -e -n "    <body>\n";
    echo -e -n "        <h2>Home Page</h2>\n";
    echo -e -n "        <?php echo '<p>This text was echoed from PHP.</p>'; ?>\n";
    echo -e -n "    </body>\n";
    echo -e -n "</html>\n";

    rm -rf /var/www/html;

# Install MySQL
    echo -e "\nInstall MySQL? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then
        apt-get -y install mysql-server;
        apt-get install python3-mysql.connector;

        echo -e "\nWhat do you want to use for a MySQL admin username? ";
        read mysqluser;
        echo -e "\nType a MySQL password for $mysqluser";
        read -s mysqlpass;

        mysql --user=root mysql -e "CREATE USER '$mysqluser'@'localhost' IDENTIFIED BY '$mysqlpass';";
        mysql --user=root mysql -e "GRANT ALL PRIVILEGES ON *.* TO '$mysqluser'@'localhost' WITH GRANT OPTION;";
        mysql --user=root mysql -e "FLUSH PRIVILEGES;";

        mysql --user=root mysql -e "set persist local_infile = 1;";

        echo -e "\nType a username for a PHP / Python MySQL user? Recommended: mysqlappadmin";
        read php_mysqluser;
        echo -e "\nType a MySQL password for $php_mysqluser";
        read -s php_mysqlpass;

        mysql --user=root mysql -e "CREATE USER '$php_mysqluser'@'localhost' IDENTIFIED BY '$php_mysqlpass';";

        echo -e "\nType a username for a CLI MySQL user? Recommended: mysqlcliadmin";
        read cli_mysqluser;
        echo -e "\nType a MySQL password for $cli_mysqluser";
        read -s cli_mysqlpass;

        mysql --user=root mysql -e "CREATE USER '$cli_mysqluser'@'localhost' IDENTIFIED BY '$cli_mysqlpass';";
        mysql --user=root mysql -e "GRANT PROCESS ON *.* TO '$cli_mysqluser'@'localhost';";

        echo -e "\nWould you like to import the MySQL databases in mysqldbs.csv? [y/n] ";
        read answer;
        if [ $answer == "y" ]; then
            while read -r mysqldb
            do
                mysql --user=root mysql -e "create database $mysqldb";
                cat ../$mysqldb.sql | mysql -D $mysqldb --user=root;

                mysql --user=root mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE ON $mysqldb.* TO '$php_mysqluser'@'localhost';";
                mysql --user=root mysql -e "GRANT LOCK TABLES,SELECT,INSERT,UPDATE,DELETE ON $mysqldb.* TO '$cli_mysqluser'@'localhost';";
                mysql --user=root mysql -e "FLUSH PRIVILEGES;";

            done < mysqldbs.csv
        fi

        rm -rf /var/cons;
        mkdir /var/cons;
        chmod 775 /var/cons;
        chown $standarduser:$standarduser /var/cons;

        echo -e "<?php" > "/var/cons/inc-db.php";
        echo -e "\$servername = 'localhost';" >> "/var/cons/inc-db.php";
        echo -e "\$username = '$php_mysqluser';" >> "/var/cons/inc-db.php";
        echo -e "\$password = '$php_mysqlpass';" >> "/var/cons/inc-db.php";
        echo -e "\$con = new mysqli(\$servername, \$username, \$password, \$db);" >> "/var/cons/inc-db.php";
        echo -e "if (\$con->connect_error) {die(\"Connection failed: \" . \$con->connect_error);}" >> "/var/cons/inc-db.php";
        echo -e "?>" >> "/var/cons/inc-db.php";

        echo -e "#!/bin/bash" > "/var/cons/inc-db.sh";
        echo -e "mysqluser='$cli_mysqluser';" >> "/var/cons/inc-db.sh";
        echo -e "mysqlpass='$cli_mysqlpass';" >> "/var/cons/inc-db.sh";

        echo -e "#!/usr/bin/python3" > "/var/cons/incdb.py";
        echo -e "import mysql.connector;" > "/var/cons/incdb.py";
        echo -e "con = mysql.connector.connect(user='$php_mysqluser', password='$php_mysqlpass', host='localhost', database='\$db', ssl_disabled=True);" > "/var/cons/incdb.py";

        chmod 640 "/var/cons/inc-db.sh";
        chmod 640 "/var/cons/inc-db.php";
        chmod 640 "/var/cons/incdb.py";
        chown $standarduser:www-data "/var/cons/inc-db.php";
        chown $standarduser:$standarduser "/var/cons/inc-db.sh";
        chown $standarduser:$standarduser "/var/cons/incdb.py";
    fi

#######################Python CRUD script
#!/usr/bin/python3

    # import mysql.connector;
    # import sys;
    # sys.path.insert(1, '/var/cons');
    # import incdb;

    # mysql_query = incdb.con.cursor();

    ##### Create
    # mysql_query.execute("INSERT INTO jobitable (jobifield1, jobifield2) VALUES ('insert into field1a', 'insert into field2a')");

    # ##### Update
    # mysql_query.execute("UPDATE mytable SET myfield = 'Updated myfield1' WHERE id = 7");

    # ##### Read
    # mysql_query.execute("SELECT * FROM testtable1");
    # records = mysql_query.fetchall();

    # for rec in records:
    #     print(str(rec[1]));
    #     print(str(rec[2]));
    
    # ##### Read One
    # mysql_query.execute("SELECT myfield FROM mytable WHERE id = 8");
    # record = mysql_query.fetchone();

    # print(record[0]);
    
    # ##### Delete
    # mysql_query.execute("DELETE FROM mytable WHERE id > 0");

    # incdb.con.commit();incdb.con.close();


# Install PHPMyAdmin
    echo -e "\nInstall PHPMyAdmin? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then
        apt-get -y install phpmyadmin;
        echo -e "Would you like to restrict PHPMyAdmin to a specific network? [y/n] ";
        read answer;
        if [ $answer == "y" ]; then
            echo -e "What network should be allowed to access PHPMyAdmin. For example, 10.0.0.0/255.255.255.0: ";
            read phpmyadminpermit;
            echo -e "\n<Directory /usr/share/phpmyadmin>" >> /etc/apache2/apache2.conf;
            echo -e "        AllowOverride None" >> /etc/apache2/apache2.conf;
            echo -e "        Require all granted" >> /etc/apache2/apache2.conf;
            echo -e "        Order Deny,Allow" >> /etc/apache2/apache2.conf;
            echo -e "        Deny from all" >> /etc/apache2/apache2.conf;
            echo -e "        Allow from 127.0.0.1" >> /etc/apache2/apache2.conf;
            echo -e "        Allow from $phpmyadminpermit" >> /etc/apache2/apache2.conf;
            echo -e "</Directory>" >> /etc/apache2/apache2.conf;
        fi
    fi

## Add index.php
    echo -e "\nAdd sample index.php to /var/www? [y/n] ";
    read answer;
    if [ $answer == "y" ]; then
        echo -e "<!DOCTYPE html>" > "/var/www/index.php";
        echo -e "<html>" > "/var/www/index.php";
        echo -e "<head>" > "/var/www/index.php";
        echo -e "    <title>Home Directory</title>" > "/var/www/index.php";
        echo -e "</head>" > "/var/www/index.php";
        echo -e "<body>" > "/var/www/index.php";
        echo -e "    <?php echo '<h2>PHP is working</h2>'; ?>" > "/var/www/index.php";
        echo -e "</body>" > "/var/www/index.php";
        echo -e "</html>" > "/var/www/index.php";

    fi