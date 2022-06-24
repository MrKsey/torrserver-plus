#!/bin/bash

echo " "
echo "============================================="
echo " "
echo "$(date): Resuming torrent downloads ..."

qbt torrent resume ALL
qbt torrent reannounce ALL

echo " "
echo "============================================="
echo " "
