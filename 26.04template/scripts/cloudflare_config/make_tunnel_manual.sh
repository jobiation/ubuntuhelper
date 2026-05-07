#!/bin/bash 

######################## NOTES ####################################

echo -e -n "\n\nRun this script as root";
echo -e -n "\n\nCreate /root/.cloudflare and put this script in that directory along with config.yml.";
echo -e -n "\n\nFor this script I am using the URL home2.tonytranquillo.com. Make sure to change it in this script and in config.yml.";
echo -e -n "\n\nChange the reference to my-tunnel if you want to name it something different.";
echo -e -n "\n\nWhen you test, go to https://home2.tonytranquillo.com even though the web service is running on regular http and on tcp port 65080.";
echo -e -n "\n\nIn testing I had to run the 'cloudflared tunnel route dns my-tunnel home2.tonytranquillo.com' command twice before I saw the DNS record show up on the Cloud Flare web console.";
echo -e -n "\n\nReference: https://chatgpt.com/share/69d25ba8-3908-832f-a6de-e248a49abe18";
echo -e -n "\n\nTo remove a tunnel, first remove the CNAME record and then run 'cloudflared tunnel delete my-tunnel'.";

##################################################################

echo -e -n "\n\nPress ENTER to continue.";
read pause;

## Add Cloud Flare repo
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list

## Apt update and upgrade
    apt update && apt upgrade;

## Install cloud flare
    apt install cloudflared;

## Run this command to login to Cloud Flare. It will give you a browser link.
## Copy the link to a desktop computer's browser and click Authorize.
## A .pem cert will be deposited in ~/.cloudflared
    cloudflared tunnel login

## Create tunnel
    cloudflared tunnel create my-tunnel
    echo -e -n "\n\nMake sure you copy the tunnel ID above and update config.yml. Press ENTER to continue.\n\n";
    read pause;

## Route the tunnel to a subdomin.
## Dp not create an A record for the subdomain in advance, a cname record should get automatically created
## If you do not see the cname record in the DNS section on the Cloud Flare site, run this command again.
    cloudflared tunnel route dns my-tunnel home2.tonytranquillo.com

## Run tunnel manually
#    cloudflared tunnel run my-tunnel

## Run as service
## It might ask you to remove /etc/cloudflare/config.yml. If so, just rename it
    cloudflared service install
    systemctl enable cloudflared
    systemctl start cloudflared

## Prompt the user to test
    echo -e -n "\n\nCloud Flare should be installed and configured.";
    echo -e -n "\n\nTo test, open a browser and browse to https://$hostname. Use https even though you are connecting on http and do not append :$tcp_port to the URL.";
    echo -e -n "\n\nIf you have trouble, make sure there is a CNAME record for the subdomain you are using.";
    echo -e -n "\n\nIf there is no CNAME record, you might need to run 'cloudflared tunnel route dns $tunnel_name $hostname' again.";
    echo -e -n "\n\nPress ENTER to exit this script";