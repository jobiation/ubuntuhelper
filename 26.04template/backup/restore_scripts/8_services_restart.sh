#!/bin/bash

for svc in apache2 nginx mysql; do
  if systemctl status "$svc" >/dev/null 2>&1; then
    systemctl restart "$svc"
  fi
done