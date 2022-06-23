#!/bin/bash

if [ -s /TS/.config.env ]; then
    set -a; . /TS/.config.env; set +a
fi

([ ! -s "$TS_STAT" ] || [ $(jq empty $TS_STAT > /dev/null 2>&1; echo $?) -ne 0 ]) && echo '{"monitor": {}, "torrents": {}}' > $TS_STAT

# Temp file for saving torrent RAW_URL
raw_url="/TS/raw_url.txt"

tail -n 0 --retry --follow=name $TS_LOG | while read line; do (
    # save torrent url to temp file
    if [ "$(echo $line | grep -o -E "add torrent .+")" ]; then
        echo RAW_URL=$(echo $line | grep -o -E "(magnet|http).+") > ${raw_url}
    fi
    
	if [ "$(echo $line | grep -o -E "Create cache for: .+")" ]; then
        HASH=$(echo $line | grep -o -E "[a-zA-Z0-9]{40}$")

        if [ "$(jq '."torrents" | has("'"$HASH"'")' $TS_STAT)" != "true" ]; then
            export $(grep -m 1 RAW_URL ${raw_url})
            NAME=$(echo $line | grep -Po "(?<=Create cache for: ).+(?=( $HASH))")

            # If RAW_URL is "magnet link" then set dn parametr to proper torrent name
            if [ ! "$(echo $RAW_URL | grep -E "^magnet:")" == "" ]; then
                export BT_URL=$(
                    TR_LIST=$(echo $RAW_URL | grep -o -E "\&tr=.+");\
                    TR_NAME=$(echo "$NAME" | jq -rR @uri);\
                    echo magnet:\?xt=urn:btih:$HASH\&dn\=$TR_NAME$TR_LIST)
            else
                export BT_URL=$RAW_URL
            fi
            jq '."torrents" += {"'"$HASH"'": {"name": "'"$NAME"'", "url": "'"$BT_URL"'", "downloaded": false}}' $TS_STAT | sponge $TS_STAT
        fi

        if [ "$(jq '."monitor" | has("'"$HASH"'")' $TS_STAT)" != "true" ] && [ "$(jq '."torrents"."'"$HASH"'"."downloaded"' $TS_STAT)" != "true" ]; then
            jq '."monitor" += {"'"$HASH"'"}' $TS_STAT | sponge $TS_STAT
        fi

    fi

    if [ "$(echo $line | grep -o -E "Close cache for: .+")" ]; then
        HASH=$(echo $line | grep -o -E "[a-zA-Z0-9]{40}$")
        jq 'del(."monitor"."'"$HASH"'")' $TS_STAT | sponge $TS_STAT
    fi
); done

