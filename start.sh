#!/bin/bash

# Stop cron
crontab -r
/etc/init.d/cron stop

# Start load configs
. /config.sh

echo "============================================="
echo " "
# Start monitoring TorrServer logfile
echo "Start monitoring TorrServer logfile ..."
tail -n 0 --retry --follow=name $TS_LOG &
echo " "

# Start monitoring qBittorrent logfile
echo "Start monitoring qBittorrent logfile ..."
tail -n 0 --retry --follow=name $TS_CONF_PATH/qBittorrent/data/logs/qbittorrent.log &
echo " "
echo "============================================="

# Updates
. /update.sh

# Start cron with logging
cron -f >> /var/log/cron.log 2>&1&

MY_IP=$(ip route get 8.8.8.8 | grep -o -E "src .+" | cut -d ' ' -f 2)

# Start qBittorrent
if [ "$QBT_ENABLED" == "true" ]; then
    echo " "
    echo "============================================="
    echo "$(date): Starting local qBittorrent ..."
    echo " "
    if [ $(pgrep qbittorrent-nox | wc -l) -eq 0 ]; then
        qbittorrent-nox -d --webui-port=$QBT_WEBUI_PORT --profile=$TS_CONF_PATH --save-path=$QBT_TORR_DIR
    fi
    qbt settings set url http://localhost:$QBT_WEBUI_PORT
    echo " "
    echo "To access local qBittorrent web interface go to: http://$MY_IP:$QBT_WEBUI_PORT"
    echo "Default LOGIN / PASSWORD: admin / adminadmin"
    echo " "
    echo "============================================="
    echo "$(date): Starting TorrServer log listener ..."
    echo " "
    /ts_log_listener.sh &
fi

# Start TorrServer
if [ $(pgrep TorrServer | wc -l) -eq 0 ]; then
    echo " "
    echo "============================================="
    echo "$(date): Starting TorrServer ..."
    echo " "
    /TS/TorrServer --path=$TS_CONF_PATH --torrentsdir=$TS_CACHE_PATH --port=$TS_PORT --logpath $TS_LOG $TS_OPTIONS &
fi
echo " "
echo "To access TorrServer web interface go to: http://$MY_IP:$TS_PORT"
echo " "
echo "============================================="

# endless work...
tail -f /dev/null
