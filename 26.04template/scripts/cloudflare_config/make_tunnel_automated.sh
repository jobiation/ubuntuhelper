#!/bin/bash 

######################## NOTES ####################################

# echo -e -n "\n\nRun this script as root";
# echo -e -n "\n\nCreate /root/.cloudflare and put this script in that directory along with config.yml.";
# echo -e -n "\n\nFor this script I am using the URL home2.tonytranquillo.com. Make sure to change it in this script and in config.yml.";
# echo -e -n "\n\nChange the reference to my-tunnel if you want to name it something different.";
# echo -e -n "\n\nWhen you test, go to https://home2.tonytranquillo.com even though the web service is running on regular http and on tcp port 65080.";
# echo -e -n "\n\nIn testing I had to run the 'cloudflared tunnel route dns my-tunnel home2.tonytranquillo.com' command twice before I saw the DNS record show up on the Cloud Flare web console.";
# echo -e -n "\n\nReference: https://chatgpt.com/share/69d25ba8-3908-832f-a6de-e248a49abe18";
# echo -e -n "\n\nTo remove a tunnel, first remove the CNAME record and then run 'cloudflared tunnel delete my-tunnel'.";

##################################################################

## Set variables
    tunnel_name="my-tunnel";
    tcp_port="65080"; ## this should be your http port, not https.
    hostname="home2.tonytranquillo.com"; ## Do not create DNS record for this in advance. CF will do it automatically.

## Prompt the user to set the variable names
    echo -e -n "\n\nBefore you begin, be sure to set the tunnel_name, tcp_port, and hostname variables.";
    echo -e -n "\n\nMake sure you are logged in a root.";
    echo -e -n "\n\nHave your Cloud Flare credentials ready.";
    echo -e -n "\n\nPress ENTER to continue or ctrl + c to exit.";
    read pause;

## Create the /root/.cloudflared directory
    if [ ! -d /root/.cloudflared ]; then
        mkdir /root/.cloudflared;
    fi

## Apt update and upgrade
    apt update && apt upgrade;

## Add Cloud Flare repo
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list

## Install cloud flare
    apt install cloudflared;

## Login to Cloud Flare
    echo -e -n "\n\nYou will be given a URL which you can copy to a desktop computer to login to Cloud Flare.";
    echo -e -n "\n\nAfter you login a file will be placed in /root/.cloudflared/cert.pem";
    echo -e -n "\n\nPress ENTER to continue.";
    cloudflared tunnel login;

## Create tunnel
    cloudflared tunnel create $tunnel_name;

    TUNNEL_FILE=$(ls -t /root/.cloudflared/*.json | head -n1);
    TUNNEL_ID=$(basename "$TUNNEL_FILE" .json);

    echo -e -n "tunnel: $tunnel_name\n" > /root/.cloudflared/config.yml;
    echo -e -n "credentials-file: /root/.cloudflared/$TUNNEL_ID.json\n" >> /root/.cloudflared/config.yml;
    echo -e -n "ingress:\n" >> /root/.cloudflared/config.yml;
    echo -e -n "  - hostname: $hostname\n" >> /root/.cloudflared/config.yml;
    echo -e -n "    service: http://localhost:$tcp_port\n" >> /root/.cloudflared/config.yml;
    echo -e -n "  - service: http_status:404\n" >> /root/.cloudflared/config.yml;

## Route the tunnel to a subdomin.
    cloudflared tunnel route dns $tunnel_name $hostname;

## Run tunnel manually
#    cloudflared tunnel run my-tunnel

## Run as service
    mv /etc/cloudflare/config.yml /etc/cloudflare/bak.config.yml;
    cloudflared service install;
    systemctl enable cloudflared;
    systemctl start cloudflared;

## Prompt the user to test
    echo -e -n "\n\nCloud Flare should be installed and configured.";
    echo -e -n "\n\nTo test, open a browser and browse to https://$hostname. Use https even though you are connecting on http and do not append :$tcp_port to the URL.";
    echo -e -n "\n\nIf you have trouble, make sure there is a CNAME record for the subdomain you are using.";
    echo -e -n "\n\nIf there is no CNAME record, you might need to run 'cloudflared tunnel route dns $tunnel_name $hostname' again.";
    echo -e -n "\n\nPress ENTER to exit this script";
