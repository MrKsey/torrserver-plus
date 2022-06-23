#!/bin/bash

echo " "
echo "=================================================="
echo "$(date): config.sh started"
echo "=================================================="
echo " "

# Start configuration:

# File ts.ini
if [ ! -s $TS_CONF_PATH/ts.ini ]; then
    # First time run. Download ts.ini from github
    wget -q --no-check-certificate --user-agent="$USER_AGENT" --content-disposition "$FILES_URL/ts.ini" -O $TS_CONF_PATH/ts.ini
    if [ -s $TS_CONF_PATH/ts.ini ]; then
        echo "$(date): File ts.ini downloaded from the github."
    else
        echo "$(date): ts.ini not downloaded, create empty"
        touch $TS_CONF_PATH/ts.ini
        tail -c1 $TS_CONF_PATH/ts.ini | read -r _ || echo >> $TS_CONF_PATH/ts.ini
    fi
fi    

if [ -s $TS_CONF_PATH/ts.ini ]; then
    chmod 666 $TS_CONF_PATH/ts.ini
    # Load config from ts.ini
    echo "$(date): Load config from ts.ini"
    sed -i -e "s/\r//g" $TS_CONF_PATH/ts.ini
    . $TS_CONF_PATH/ts.ini && export $(grep --regexp ^[a-zA-Z] $TS_CONF_PATH/ts.ini | cut -d= -f1)
    echo "=================================================="
    echo "$(date): Configuration settings from ts.ini file:"
    echo " "
    echo "$(cat $TS_CONF_PATH/ts.ini | grep --regexp ^[a-zA-Z])"
    echo " "
    echo "=================================================="
    echo " "
fi


# File accs.db
if [ ! -s $TS_CONF_PATH/accs.db ]; then
    wget -q --no-check-certificate --user-agent="$USER_AGENT" --content-disposition "$FILES_URL/accs.db" -O $TS_CONF_PATH/accs.db
    if [ -s $TS_CONF_PATH/accs.db ]; then
        echo " "
        echo "============================================="
        echo "$(date): File accs.db downloaded from the github."
        echo "============================================="
        echo " "
    else
        rm -f $TS_CONF_PATH/accs.db
    fi
fi

# File config.db
if [ ! -s $TS_CONF_PATH/config.db ]; then
    wget -q --no-check-certificate --user-agent="$USER_AGENT" --content-disposition "$FILES_URL/config.db" -O $TS_CONF_PATH/config.db
    if [ -s $TS_CONF_PATH/config.db ]; then
        echo " "
        echo "============================================="
        echo "$(date): File config.db downloaded from the github."
        echo "============================================="
        echo " "
    else
        rm -f $TS_CONF_PATH/config.db
    fi
fi

# File qBittorrent.conf
if [ ! -s $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf ]; then
    mkdir -p $TS_CONF_PATH/qBittorrent/config && chmod -R 666 $TS_CONF_PATH/qBittorrent/config
    wget -q --no-check-certificate --user-agent="$USER_AGENT" --content-disposition "$FILES_URL/qBittorrent.conf" -O $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf
    if [ -s $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf ]; then
        echo " "
        echo "============================================="
        echo "$(date): File qBittorrent.conf downloaded from the github."
        echo "============================================="
        echo " "
    else
        cat <<EOT >> $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf
[BitTorrent]
Session\AddTrackersEnabled=true
Session\AdditionalTrackers=http://bt.t-ru.org/ann?magnet\nhttp://bt2.t-ru.org/ann?magnet\nhttp://bt3.t-ru.org/ann?magnet\nhttp://bt4.t-ru.org/ann?magnet\nhttp://tracker.dler.org:6969/announce\nhttp://tracker.files.fm:6969/announce\nhttp://tracker.internetwarriors.net:1337/announce\nhttp://tracker2.itzmx.com:6961/announce\nhttp://tracker.openbittorrent.com:80/announce\nudp://opentor.net:6969\nudp://open.stealth.si:80/announce\nudp://exodus.desync.com:6969/announce\nudp://tracker.openbittorrent.com:80/announce\nudp://tracker.openbittorrent.com:6969/announce\nudp://tracker.tiny-vps.com:6969/announce\nudp://tracker.bitsearch.to:1337/announce\nudp://tracker.moeking.me:6969/announce\n
Session\AlternativeGlobalDLSpeedLimit=(SPEEDTEST)
Session\AlternativeGlobalUPSpeedLimit=(SPEEDTEST)
Session\AnnounceToAllTiers=true
Session\AnnounceToAllTrackers=true
Session\BandwidthSchedulerEnabled=true
Session\DefaultSavePath=(QBT_TORR_DIR)
Session\GlobalDLSpeedLimit=(SPEEDTEST)
Session\GlobalUPSpeedLimit=(SPEEDTEST)
Session\IgnoreLimitsOnLAN=true
Session\MultiConnectionsPerIp=true
Session\UseAlternativeGlobalSpeedLimit=true
Session\IPFilter=(TS_CONF_PATH)/bip.dat
Session\IPFilteringEnabled=true
TrackerEnabled=true

[Core]
AutoDeleteAddedTorrentFile=IfAdded

[Preferences]
Advanced\trackerPort=(QBT_TRACKER_PORT)
Scheduler\days=EveryDay
Scheduler\end_time=@Variant(\0\0\0\xf\0m\xdd\0)
Scheduler\start_time=@Variant(\0\0\0\xf\x1I\x97\0)
WebUI\LocalHostAuth=false
WebUI\UseUPnP=false

EOT
    fi
fi


# Folder for TS disk cache
[ ! -d "$TS_CACHE_PATH" ] && mkdir -p $TS_CACHE_PATH && chmod -R 777 $TS_CACHE_PATH
[ ! -d "/cache" ] && ln -s $TS_CACHE_PATH /cache

# Folder for qBittorrent downloads
[ ! -d "$QBT_TORR_DIR" ] && mkdir -p $QBT_TORR_DIR && chmod -R 777 $QBT_TORR_DIR

# Reset list of monitoring hashes in TS_STAT file
[ -s "$TS_STAT" ] && [ $(jq empty $TS_STAT > /dev/null 2>&1; echo $?) -eq 0 ] && jq '."monitor" = {}' $TS_STAT | sponge $TS_STAT


# Check vars, set defaults in ts.ini ==========================
echo "$(date): Check vars, set defaults..."

#  TS_RELEASE
[ -z "$TS_RELEASE" ] && export TS_RELEASE=latest
sed -i "/^TS_RELEASE=/{h;s/=.*/=${TS_RELEASE}/};\${x;/^$/{s//TS_RELEASE=${TS_RELEASE}/;H};x}" $TS_CONF_PATH/ts.ini

#  TS_PORT
[ -z "$TS_PORT" ] && export TS_PORT=8090
sed -i "/^TS_PORT=/{h;s/=.*/=${TS_PORT}/};\${x;/^$/{s//TS_PORT=${TS_PORT}/;H};x}" $TS_CONF_PATH/ts.ini

#  TS_OPTIONS
[ ! -z "$TS_OPTIONS" ] && export TS_OPTIONS="\"$TS_OPTIONS\""
sed -i -E "s/TS_OPTIONS=(.*)/TS_OPTIONS=\"\1\"/" $TS_CONF_PATH/ts.ini
sed -i "s/\"\"/\"/g" $TS_CONF_PATH/ts.ini

#  OS_UPDATE
[ -z "$OS_UPDATE" ] && export OS_UPDATE=true
[ "$OS_UPDATE" != "true" ] && export OS_UPDATE=false
sed -i "/^OS_UPDATE=/{h;s/=.*/=${OS_UPDATE}/};\${x;/^$/{s//OS_UPDATE=${OS_UPDATE}/;H};x}" $TS_CONF_PATH/ts.ini

#  BIP_URL
if [ ! -z "$BIP_URL" ]; then
    export BIP_URL="\"$BIP_URL\""
    sed -i -E "s/BIP_URL=(.*)/BIP_URL=\"\1\"/" $TS_CONF_PATH/ts.ini
    sed -i "s/\"\"/\"/g" $TS_CONF_PATH/ts.ini
fi

#  UPDATE_TASK (TS and linux updates)
if [ -z "$UPDATE_TASK" ]; then
    # generate update time in interval 3-4h and 0-59m 
    UPDATE_H=$(shuf -i3-4 -n1)
    UPDATE_M=$(shuf -i0-59 -n1)
    export UPDATE_TASK="\"$UPDATE_M $UPDATE_H \* \* \*\""
fi
sed -i "/^UPDATE_TASK=/{h;s/=.*/=${UPDATE_TASK}/};\${x;/^$/{s//UPDATE_TASK=${UPDATE_TASK}/;H};x}" $TS_CONF_PATH/ts.ini
sed -i -E "s/UPDATE_TASK=(.*)/UPDATE_TASK=\"\1\"/" $TS_CONF_PATH/ts.ini
sed -i "s/\"\"/\"/g" $TS_CONF_PATH/ts.ini

# Add update task to cron
if [ ! -z "$UPDATE_TASK" ]; then
    crontab -l | { cat; echo "$(echo "$UPDATE_TASK" | sed 's/\\//g' | sed "s/\"//g") /update.sh >> /var/log/cron.log 2>&1"; } | crontab -
fi

#  FFPROBE_UPDATE (ffprobe is a part of the ffmpeg package)
[ -z "$FFPROBE_UPDATE" ] && export FFPROBE_UPDATE=true
[ "$FFPROBE_UPDATE" != "true" ] && export FFPROBE_UPDATE=false
sed -i "/^FFPROBE_UPDATE=/{h;s/=.*/=${FFPROBE_UPDATE}/};\${x;/^$/{s//FFPROBE_UPDATE=${FFPROBE_UPDATE}/;H};x}" $TS_CONF_PATH/ts.ini

#  QBT_ENABLED
[ -z "$QBT_ENABLED" ] && export QBT_ENABLED=true
[ "$QBT_ENABLED" != "true" ] && export QBT_ENABLED=false
sed -i "/^QBT_ENABLED=/{h;s/=.*/=${QBT_ENABLED}/};\${x;/^$/{s//QBT_ENABLED=${QBT_ENABLED}/;H};x}" $TS_CONF_PATH/ts.ini


# Set parameters in file qBittorrent.conf
if [ "$QBT_ENABLED" == "true" ]; then
    echo " "
    echo "----------------------------------------"
    echo " "
    echo "$(date): qBittorrent enabled. Setting parameters in qBittorrent.conf ..."
    if [ $(grep "SPEEDTEST" $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf | wc -l) -gt 0 ]; then
        # Test internet speed
        echo "$(date): Testing internet speed ..."
        speedtest --json > $TS_CONF_PATH/speedtest.json
            
        # download speed, kbit/s
        DOWNLOAD_SPEED=$(jq '.download' $TS_CONF_PATH/speedtest.json | awk '{print int($1+0.5)}')
        DOWNLOAD_SPEED=$(($DOWNLOAD_SPEED / 1024))
            
        # upload speed, kbit/s
        UPLOAD_SPEED=$(jq '.upload' $TS_CONF_PATH/speedtest.json | awk '{print int($1+0.5)}')
        UPLOAD_SPEED=$(($UPLOAD_SPEED / 1024))
        
        # QBT day speed limit = 20% of internet speed, KBytes/s
        QBT_DL_DAY_SPEED=$(((($DOWNLOAD_SPEED * 20) / 100) / 8))
        QBT_UP_DAY_SPEED=$(((($UPLOAD_SPEED * 20) / 100) / 8))
        sed -i "s/Session\\\AlternativeGlobalDLSpeedLimit=(SPEEDTEST)/Session\\\AlternativeGlobalDLSpeedLimit=${QBT_DL_DAY_SPEED}/g" $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf
        sed -i "s/Session\\\AlternativeGlobalUPSpeedLimit=(SPEEDTEST)/Session\\\AlternativeGlobalUPSpeedLimit=${QBT_UP_DAY_SPEED}/g" $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf
        echo "$(date): Set qBittorrent day download/upload limits: $QBT_DL_DAY_SPEED / $QBT_UP_DAY_SPEED KByte/s"
            
        # QBT night speed limit = 80% of internet speed, KBytes/s
        QBT_DL_NIGHT_SPEED=$(((($DOWNLOAD_SPEED * 80) / 100) / 8))
        QBT_UP_NIGHT_SPEED=$(((($UPLOAD_SPEED * 80) / 100) / 8))
        sed -i "s/Session\\\GlobalDLSpeedLimit=(SPEEDTEST)/Session\\\GlobalDLSpeedLimit=${QBT_DL_NIGHT_SPEED}/g" $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf
        sed -i "s/Session\\\GlobalUPSpeedLimit=(SPEEDTEST)/Session\\\GlobalUPSpeedLimit=${QBT_UP_NIGHT_SPEED}/g" $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf
        echo "$(date): Set qBittorrent night download/upload limits: $QBT_DL_NIGHT_SPEED / $QBT_UP_NIGHT_SPEED KByte/s"
    fi
        
    #  QBT_TRACKER_PORT
    export QBT_TRACKER_PORT=$(grep "trackerPort" $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf | grep -o -E "[0-9]+")
    if [ -z "$QBT_TRACKER_PORT" ]; then
        export QBT_TRACKER_PORT=9999
        sed -i "s/Advanced\\\trackerPort=(QBT_TRACKER_PORT)/Advanced\\\trackerPort=${QBT_TRACKER_PORT}/g" $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf
    fi
    if [ $(grep "QBT_TRACKER_PORT" $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf | wc -l) -gt 0 ]; then
        export QBT_TRACKER_PORT=9999
        sed -i "s/Advanced\\\trackerPort=(QBT_TRACKER_PORT)/Advanced\\\trackerPort=${QBT_TRACKER_PORT}/g" $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf
    fi
    echo "$(date): Set qBittorrent tracker port to $QBT_TRACKER_PORT"
    
    #  QBT_LOCAL_TRACKER
    export QBT_LOCAL_TRACKER="http://localhost:$QBT_TRACKER_PORT/announce"
    if [ ! -s $TS_CONF_PATH/trackers.txt ]; then
        echo $QBT_LOCAL_TRACKER > $TS_CONF_PATH/trackers.txt
        chmod a+r $TS_CONF_PATH/trackers.txt
    else
        if [ -z "$(grep $QBT_LOCAL_TRACKER /TS/db/trackers.txt)" ]; then
            echo $QBT_LOCAL_TRACKER >> $TS_CONF_PATH/trackers.txt
        fi
    fi
    
    #  QBT_WEBUI_PORT
    [ -z "$QBT_WEBUI_PORT" ] && export QBT_WEBUI_PORT=8888
    sed -i "/^QBT_WEBUI_PORT=/{h;s/=.*/=${QBT_WEBUI_PORT}/};\${x;/^$/{s//QBT_WEBUI_PORT=${QBT_WEBUI_PORT}/;H};x}" $TS_CONF_PATH/ts.ini
    
    #  QBT_TORR_DIR
    if [ $(grep "QBT_TORR_DIR" $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf | wc -l) -gt 0 ]; then
        sed -i "s|Session\\\DefaultSavePath=(QBT_TORR_DIR)|Session\\\DefaultSavePath=${QBT_TORR_DIR}|g" $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf
        echo "$(date): Set qBittorrent download dir to $QBT_TORR_DIR"
    fi

    #  QBT_DOWNLOAD_THRESHOLD (from 0 to 100 %)
    [ -z "$QBT_DOWNLOAD_THRESHOLD" ] && export QBT_DOWNLOAD_THRESHOLD=30
    [ $QBT_DOWNLOAD_THRESHOLD -lt 0 ] && export QBT_DOWNLOAD_THRESHOLD=0
    [ $QBT_DOWNLOAD_THRESHOLD -gt 100 ] && export QBT_DOWNLOAD_THRESHOLD=100
    sed -i "/^QBT_DOWNLOAD_THRESHOLD=/{h;s/=.*/=${QBT_DOWNLOAD_THRESHOLD}/};\${x;/^$/{s//QBT_DOWNLOAD_THRESHOLD=${QBT_DOWNLOAD_THRESHOLD}/;H};x}" $TS_CONF_PATH/ts.ini

    #  QBT_ADD_PAUSED
    [ -z "$QBT_ADD_PAUSED" ] && export QBT_ADD_PAUSED=false
    [ "$QBT_ADD_PAUSED" != "false" ] && export QBT_ADD_PAUSED=true
    sed -i "/^QBT_ADD_PAUSED=/{h;s/=.*/=${QBT_ADD_PAUSED}/};\${x;/^$/{s//QBT_ADD_PAUSED=${QBT_ADD_PAUSED}/;H};x}" $TS_CONF_PATH/ts.ini
    
    #  QBT_ADD_MORE_TRACKERS
    [ -z "$QBT_ADD_MORE_TRACKERS" ] && export QBT_ADD_MORE_TRACKERS=true
    [ "$QBT_ADD_MORE_TRACKERS" != "true" ] && export QBT_ADD_MORE_TRACKERS=false
    sed -i "/^QBT_ADD_MORE_TRACKERS=/{h;s/=.*/=${QBT_ADD_MORE_TRACKERS}/};\${x;/^$/{s//QBT_ADD_MORE_TRACKERS=${QBT_ADD_MORE_TRACKERS}/;H};x}" $TS_CONF_PATH/ts.ini

    # Authorization in TorrServer for qbt_manager.sh
    export POST_AUTH=""
    if [ $(jq empty $TS_CONF_PATH/accs.db > /dev/null 2>&1; echo $?) -eq 0 ] && [ "$(echo "$TS_OPTIONS" | grep "\-a")" ]; then
        TS_AUTH=$(jq -r 'to_entries[0] | [.key, .value] | @tsv' $TS_CONF_PATH/accs.db | tr '\t' ':' | tr -d '\n' | base64)
        [ ! -z "$TS_AUTH" ] && export POST_AUTH="$TS_AUTH"
    fi
    
    #  QBT_CHECKS_TIMER (check TS_STAT file every N minutes (from 1 to 10 minutes)) 
    [ -z "$QBT_CHECKS_TIMER" ] && export QBT_CHECKS_TIMER=5
    [ $QBT_CHECKS_TIMER -lt 1 ] && export QBT_CHECKS_TIMER=1
    [ $QBT_CHECKS_TIMER -gt 10 ] && export QBT_CHECKS_TIMER=10
    sed -i "/^QBT_CHECKS_TIMER=/{h;s/=.*/=${QBT_CHECKS_TIMER}/};\${x;/^$/{s//QBT_CHECKS_TIMER=${QBT_CHECKS_TIMER}/;H};x}" $TS_CONF_PATH/ts.ini

    export QBT_CHECKS_TASK="\"\*/$QBT_CHECKS_TIMER \* \* \* \*\""
    crontab -l | { cat; echo "$(echo "$QBT_CHECKS_TASK" | sed 's/\\//g' | sed "s/\"//g") /qbt_manager.sh >> /var/log/cron.log 2>&1"; } | crontab -
        
    #  QBT_RESUME_HOUR (resume downloading all torrents at specified hour (from 0 to 23 hour))
    if [ ! -z "$QBT_RESUME_HOUR" ]; then
        [ $QBT_RESUME_HOUR -lt 0 ] && export QBT_RESUME_HOUR=0
        [ $QBT_RESUME_HOUR -gt 23 ] && export QBT_RESUME_HOUR=23
        sed -i "/^QBT_RESUME_HOUR=/{h;s/=.*/=${QBT_RESUME_HOUR}/};\${x;/^$/{s//QBT_RESUME_HOUR=${QBT_RESUME_HOUR}/;H};x}" $TS_CONF_PATH/ts.ini
        
        export QBT_RESUME_TASK="\"\* $QBT_RESUME_HOUR \* \* \*\""
        crontab -l | { cat; echo "$(echo "$QBT_RESUME_TASK" | sed 's/\\//g' | sed "s/\"//g") /qbt_resume_torrents.sh >> /var/log/cron.log 2>&1"; } | crontab -
    fi
    
    #  QBT_IPFilter
    if [ $(grep "(TS_CONF_PATH)/bip.dat" $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf | wc -l) -gt 0 ]; then
        sed -i "s|Session\\\IPFilter=(TS_CONF_PATH)/bip.dat|Session\\\IPFilter=${TS_CONF_PATH}/bip.dat|g" $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf
    fi
    
    if [ ! -z "$BIP_URL" ]; then
        export QBT_IP_FILTER_ENABLED=$(grep "Session\\\IPFilteringEnabled" $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf | cut -d '=' -f 2)
        [ "$QBT_IP_FILTER_ENABLED" != "true" ] && export QBT_IP_FILTER_ENABLED=false
    else
        export QBT_IP_FILTER_ENABLED=false    
    fi
    sed -i -e "s|Session\\\IPFilteringEnabled=.*|Session\\\IPFilteringEnabled=${QBT_IP_FILTER_ENABLED}|g" $TS_CONF_PATH/qBittorrent/config/qBittorrent.conf
    
    echo " "
    echo "----------------------------------------"
    echo " "    
fi


# Save ENV VARS to file
echo "$(date): Save ENV VARS to file"
env | grep -v "_TASK" | awk 'NF {sub("=","=\"",$0); print ""$0"\""}' > /TS/.config.env && chmod 644 /TS/.config.env
#env | grep -v "_TASK" | awk 'NF {sub("=","=\"",$0); print ""$0"\""}' | sed -E "s/=(.*) /=\'\1 /" | sed -E "s/ (.*)$/= \1\'/" > /TS/.config.env && chmod 644 /TS/.config.env
# sed -i "s/\"\"/\"/g" /TS/.config.env && sed -i "s/=\"$/=\"\"/g" /TS/.config.env
sed -i -E "s/=\"\"(.+)\"\"/=\"\1\"/g" /TS/.config.env

# Fixing single qoute
sed -i -E "s/(^[A-Za-z_]+=)\"$/\1\"\"/g" $TS_CONF_PATH/ts.ini

echo " "
echo "=================================================="
echo "$(date): config.sh finished"
echo "=================================================="
echo " "
