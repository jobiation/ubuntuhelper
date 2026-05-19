#!/bin/bash

## Executes at 6 minutes past 2:00 AM: 6 2 * * *

## Update the server
    /usr/bin/apt-get -y update && /usr/bin/apt-get -y upgrade

## Backup the server
    /usr/bin/systemctl stop mcbedrock;
    /var/local/mcbedrock/mcbedrock.log;
    /var/local/backup/backup.sh
    # /usr/bin/systemctl start mcbedrock;

## Restart the server
    /usr/sbin/shutdown -r now


