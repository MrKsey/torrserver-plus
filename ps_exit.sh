#!/bin/bash

echo " "
echo "=================================================="
echo " "
# Graceful shutdown container
echo "$(date): Graceful shutdown container ..."

pkill -15 cron

# Gracefull shutdown qBittorrent
TIMER=5
pkill -2 -f "^"qbittorrent-nox
while [ $(pgrep qbittorrent-nox | wc -l) -gt 0 ]; do
    if [ $TIMER -eq 0 ]; then
        pkill -9 -f "^"qbittorrent-nox
        break
    else
        TIMER=$(($TIMER - 1))
        sleep 1
    fi
done
    
# Gracefull shutdown TorrServer
TIMER=3
pkill -15 -f "^"/TS/TorrServer
while [ $(pgrep TorrServer | wc -l) -gt 0 ]; do
    if [ $TIMER -eq 0 ]; then
        pkill -9 -f "^"/TS/TorrServer
        break
    else
        TIMER=$(($TIMER - 1))
        sleep 1
    fi
done

sync

pkill -15 tail
pkill -15 bash
echo " "
echo "=================================================="
