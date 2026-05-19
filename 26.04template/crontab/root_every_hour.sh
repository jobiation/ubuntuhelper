#!/bin/bash

## Executes at 5 past the hour: 5 * * * *

## Update time
    cp /usr/share/zoneinfo/EST5EDT /etc/localtime
    /usr/sbin/ntpdate -s time.nist.gov;