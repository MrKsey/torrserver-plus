#!/bin/bash

echo " "
echo "=================================================="
echo " "
# Graceful shutdown container
echo "$(date): Graceful shutdown container ..."
pkill -2 -f "^"qbittorrent-nox
pkill -15 -f "^"/TS/TorrServer
sync
ps aux | grep -E "(qbittorrent-nox|/TS/TorrServer)" | grep -v "grep"
echo " "
echo "=================================================="
