#!/bin/bash

echo " "
echo "=================================================="
echo " "
# Graceful shutdown container
echo "$(date): Graceful shutdown container ..."
pkill -15 cron
pkill -2 -f "^"qbittorrent-nox
pkill -15 -f "^"/TS/TorrServer
sync
sleep 3
pkill -15 tail
pkill -15 bash
echo " "
echo "=================================================="
