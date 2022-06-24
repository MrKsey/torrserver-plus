#!/bin/bash

echo " "
echo "=================================================="
echo "$(date): update.sh started"
echo "=================================================="
echo " "

if [ -s /TS/.config.env ]; then
    set -a; . /TS/.config.env; set +a
fi

TS_RESTART=false
QBT_RESTART=false
mkdir -p /tmp/ts && cd /tmp/ts

# Update OS
if [ "$OS_UPDATE" == "true" ]; then
    echo " "
    echo "=================================================="
    echo "$(date): Start checking for OS updates ..."
    echo " "
    
    apt-get update
    if [ $(apt list --upgradable 2>/dev/null | wc -l) -gt 1 ]; then
        apt-get upgrade -y && apt-get purge -y -q --auto-remove
        TS_RESTART=true
        QBT_RESTART=true
        strip --remove-section=.note.ABI-tag $(find /usr/. -name "libQt5Core.so.5")
    fi
    
    echo " "
    echo "$(date): Finished checking for OS updates."
    echo "=================================================="
    echo " "
fi


# ffprobe updates
if [ "$FFPROBE_UPDATE" == "true" ]; then
    echo " "
    echo "=================================================="
    echo "$(date): Start checking for ffprobe updates ..."
    echo " "
    
    [ $(which ffprobe | wc -l) -gt 0 ] && FFPROBE_LOCAL_VER=$(ffprobe -version | grep -o -E "version [0-9\.]+" | cut -d " " -f 2) || FFPROBE_LOCAL_VER="none"
    FFPROBE_REMOTE_VER=$(curl -s $FFBINARIES | jq -r '.version')
    
    if [ ! -z "$FFPROBE_REMOTE_VER" ] && [ "$FFPROBE_LOCAL_VER" != "$FFPROBE_REMOTE_VER" ]; then    
        wget --no-verbose --no-check-certificate --user-agent="$USER_AGENT" --output-document=/tmp/ts/ffprobe.zip --tries=3 $(\
        curl -s $FFBINARIES | jq '.bin | .[].ffprobe' | grep linux | \
        grep -i -E "$(dpkg --print-architecture | sed "s/amd64/linux-64/g" | sed "s/arm64/linux-arm-64/g" | sed -E "s/armhf/linux-armhf-32/g")" | jq -r)
        if [ $? -eq 0 ]; then
            unzip -x -o /tmp/ts/ffprobe.zip ffprobe -d /usr/local/bin
            chmod -R +x /usr/local/bin
            echo " "
            ffprobe -version
            TS_RESTART=true
        else
            echo "$(date): Error updating ffprobe from URL: $FFBINARIES"
        fi
    else
        if [ -z "$FFPROBE_REMOTE_VER" ]; then
            echo "$(date): Error updating ffprobe from URL: $FFBINARIES"
        else
            echo "$(date): ffprobe version $FFPROBE_LOCAL_VER is latest. Nothing to update."
        fi
    fi
    echo " "
    echo "$(date): Finished checking for ffprobe updates."
    echo "=================================================="
    echo " "
fi


# Start checking for blacklist ip updates
if [ ! -z "$BIP_URL" ]; then
    echo " "
    echo "=================================================="
    echo "$(date): Start checking for blacklist ip updates ..."
    echo " "
            
    # Get remote file extension and size
    resp=$(wget -v --spider --no-check-certificate --user-agent="$USER_AGENT" --content-disposition "$BIP_URL" -O - 2>&1 | grep -E "(http|Length:)")
    
    bip_url=$(echo $resp | grep -Po "(?<= )http.+(?=( Length:))" | sed "s/ /\n/g" | tail -1)
    [ ! -z "$bip_url" ] && export EXT=$(basename $bip_url | grep -o -E "[^.]*$")
    
    file_size=$(echo $resp | grep -o -E "Length: [0-9]+" | cut -d " " -f 2)
    [ ! -z "$file_size" ] && export BIP_REMOTE_SIZE=$file_size || export BIP_REMOTE_SIZE=0
            
    # Get local file size
    [ -s "/TS/bip_local_size.txt" ] && . /TS/bip_local_size.txt || BIP_LOCAL_SIZE=0
        
    if [ $BIP_REMOTE_SIZE -gt 0 ] && [ $BIP_LOCAL_SIZE -ne $BIP_REMOTE_SIZE ]; then
        wget -nv --no-check-certificate --user-agent="$USER_AGENT" --content-disposition "$BIP_URL" --output-document=/TS/bip_raw.$EXT
        
        file -b --mime-type /TS/bip_raw.$EXT | ( grep -q 'text/plain' && cat /TS/bip_raw.$EXT 2>&1 || gunzip -c /TS/bip_raw.$EXT) | \
        egrep -v '^#' | tr -d "[:blank:]" | \
        awk '{gsub("[a-zA-Z][0-9]+\.[0-9]+\.[0-9]+\.[0-9]+","");print}' | \
        awk '{gsub("[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[a-zA-Z]","");print}' | \
        egrep -o '([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})' | \
        sed -r 's/0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)/\1.\2.\3.\4/g' | \
        egrep -v '^(0|22[4-9]|2[3-5]|192\.168\.[0-9]{1,3}\.[0-9]{1,3})' | \
        sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n -u > /TS/bip.txt
        
        bip_size=$(wc -l /TS/bip.txt | cut -f 1 -d ' ')
        if [ $bip_size -gt 1024 ]; then
            # set BIP_LOCAL_SIZE=<zipped size>
            echo BIP_LOCAL_SIZE=$(du -b "/TS/bip_raw.$EXT" | cut -f 1) > /TS/bip_local_size.txt
            rm -f /TS/bip_raw.$EXT
            
            # if bip.txt size more then 1Kb ...
            cp -f /TS/bip.txt $TS_CONF_PATH/bip.txt
            chmod a+r $TS_CONF_PATH/bip.txt
            echo " "
            echo "$(date): New bip.txt size: $bip_size strings."
            echo " "
            
            # Converting bip.txt to bip.dat for qBittorent
            if [ "$QBT_ENABLED" == "true" ]; then
                echo "$(date): Converting bip.txt to bip.dat for qBittorent ..."
                cat $TS_CONF_PATH/bip.txt | sed "s/-/ . /g" | awk -F. '{printf "%03d.%03d.%03d.%03d - %03d.%03d.%03d.%03d\n",$1,$2,$3,$4,$5,$6,$7,$8}' | sed -z "s/\n/ , 000 , bip \n/g" > /$TS_CONF_PATH/bip.dat
                [ "$QBT_IP_FILTER_ENABLED" == "true" ] && QBT_RESTART=true
            fi

            rm -f /TS/bip.txt
            TS_RESTART=true
        else
            echo "$(date): Error updating blacklist ip from URL: $BIP_URL"
        fi
    else
        if [ $BIP_REMOTE_SIZE -gt 0 ]; then
            echo "$(date): Blacklist ip file is latest. Nothing to update."
        else
            echo "$(date): Remote Blacklist ip file size is zero. Check the url: $BIP_URL"
        fi
    fi
    
    echo " "
    echo "$(date): Finished checking for blacklist ip updates."
    echo "=================================================="
    echo " "
fi


# Update trackers list
if [ "$QBT_ENABLED" == "true" ] && [ "$QBT_ADD_MORE_TRACKERS" == "true" ]; then
    echo " "
    echo "=================================================="
    echo "$(date): Start updating additional trackers list ..."
    echo " "
    curl -f -s $QBT_TRACKERS_URL | grep -E "^(udp|http)" > /TS/trackers.tmp
    list_size=$(wc -l /TS/trackers.tmp | cut -f 1 -d ' ')
    if [ $list_size -gt 1 ]; then
        TRACKERS=""
        for tracker in $(cat /TS/trackers.tmp)
        do
            TRACKERS="$TRACKERS $tracker"
        done
        echo $TRACKERS > /TS/more_trackers.txt
        chmod a+r /TS/more_trackers.txt
        echo " "
        echo "$(date): New trackers list size: $list_size strings."
        rm -f /TS/trackers.tmp
    else
        echo "$(date): Error updating trackers list from URL: $QBT_TRACKERS_URL"
    fi
fi


# Update TorrServer
# =======================================================

if [ "$(curl -o /dev/null -s -w '%{http_code}\n' $TS_GIT_URL)" != "200" ]; then
    export TS_URL=$TS_HOME_URL
else
    export TS_VER=$([ "$TS_RELEASE" != "latest" ] && echo tags/$TS_RELEASE || echo $TS_RELEASE)
    export TS_URL=$TS_GIT_URL/$TS_VER
fi

[ -s /TS/TorrServer ] && TS_LOCAL_VER=$(/TS/TorrServer --version | cut -d ' ' -f 2) || TS_LOCAL_VER="none"
TS_REMOTE_VER=$(curl -f -s $TS_URL | grep -E "(version|tag_name)" | cut -d ':' -f 2 | grep -o -E '\".+\"' | jq -r)

echo " "
echo "=================================================="
echo "$(date): Start checking for TorrServer updates ..."
echo " "

if [ ! -z "$TS_REMOTE_VER" ] && [ "$TS_LOCAL_VER" != "$TS_REMOTE_VER" ]; then
    echo "$(date): Updating TorrServer to version $TS_REMOTE_VER ..."
    echo " "
    wget --no-verbose --no-check-certificate --user-agent="$USER_AGENT" --output-document=/tmp/ts/TorrServer --tries=3 \
    $(curl -s $TS_URL | grep -o -E 'http.+\w+' | grep -i "$(uname)" | grep -i "$(dpkg --print-architecture | sed "s/armhf/arm7/g")")
    if [ $? -eq 0 ]; then
        chmod a+x /tmp/ts/TorrServer
        TS_NEW_VER=$(/tmp/ts/TorrServer --version | cut -d ' ' -f 2)
        if [ $? -eq 0 ] && [ ! -z "$TS_NEW_VER" ] && [ "$TS_NEW_VER" == "$TS_REMOTE_VER" ]; then
            cp -f /tmp/ts/TorrServer /TS/TorrServer
            chmod a+x /TS/TorrServer
            TS_LOCAL_VER=$(/TS/TorrServer --version | cut -d ' ' -f 2)
            TS_RESTART=true
            echo " "
            echo "$(date): TorrServer updated to version $TS_LOCAL_VER"
            echo "=================================================="
            echo " "
        else
            echo " "
            echo "$(date): Error during the update process: downloaded file is corrupted. TorrServer not updated."
            echo "=================================================="
            echo " "
        fi
    else
        echo " "
        echo "$(date): Update TorrServer failed. Check update source url: $TS_URL"
        echo "=================================================="
        echo " "
    fi
else
    if [ -z "$TS_REMOTE_VER" ]; then
        echo "$(date): Update TorrServer failed. Check update source url: $TS_URL"
    else
        echo "$(date): Local TorrServer version is $TS_LOCAL_VER. Nothing to update or re-download."
    fi
    echo "=================================================="
    echo " "
fi
# =======================================================

cd / && rm -rf /tmp/ts


# Cut TS log file
if [ -s $TS_LOG ]; then
    echo " "
    echo "=================================================="
    echo "$(date): Truncating TS log file ..."
    echo "" > $TS_LOG
fi


# Restarting qBittorrent after all updates
if [ "$QBT_ENABLED" == "true" ] && [ "$QBT_RESTART" == "true" ]; then
    echo " "
    echo "=================================================="
    echo "$(date): Restarting qBittorrent after all updates ..."
    echo " "
    sync
    pkill -2 -f "^"qbittorrent-nox
    if [ $(pgrep qbittorrent-nox | wc -l) -eq 0 ]; then
        qbittorrent-nox -d --webui-port=$QBT_WEBUI_PORT --profile=$TS_CONF_PATH --save-path=$QBT_TORR_DIR
        sleep 5
    fi
fi

# Restarting TorrServer after all updates
if [ "$TS_RESTART" == "true" ]; then
    echo " "
    echo "=================================================="
    echo "$(date): Restarting TorrServer after all updates ..."
    echo " "
    sync
    pkill -15 -f "^"/TS/TorrServer
    
    # Reset list of monitoring hashes in TS_STAT file
    [ -s "$TS_STAT" ] && [ $(jq empty $TS_STAT > /dev/null 2>&1; echo $?) -eq 0 ] && jq '."monitor" = {}' $TS_STAT | sponge $TS_STAT
    
    if [ $(pgrep TorrServer | wc -l) -eq 0 ]; then
        /TS/TorrServer --path=$TS_CONF_PATH --torrentsdir=$TS_CACHE_PATH --port=$TS_PORT --logpath $TS_LOG $TS_OPTIONS &
        sleep 5
    fi
fi

echo " "
echo "=================================================="
echo "$(date): update.sh finished"
echo "=================================================="
echo " "
