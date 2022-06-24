#!/bin/bash

if [ -s /TS/.config.env ]; then
    set -a; . /TS/.config.env; set +a
fi

if [ -s $TS_STAT ]; then
    
    # POST_AUTH="Cache-Control: no-cache" - it's just a dummy header instead of an authorization header
    [ ! -z "$POST_AUTH" ] && POST_AUTH="Authorization:Basic $POST_AUTH" || POST_AUTH="Cache-Control: no-cache"
    
    QBT_TORRENTS_LIST=($(qbt torrent list -F json | grep -w "hash" | grep -o -E "[a-zA-Z0-9]{40}"))

    for HASH in $(jq '."monitor" | keys' $TS_STAT | grep -o -E "[a-zA-Z0-9]{40}")
    do
        if [ ! -z "$HASH" ] && [[ " ${QBT_TORRENTS_LIST[*]} " =~ " ${HASH} " ]]; then
            jq '."torrents"."'"$HASH"'"."downloaded" = true' $TS_STAT | sponge $TS_STAT
            jq 'del(."monitor"."'"$HASH"'")' $TS_STAT | sponge $TS_STAT
        else
            TORRENT_SIZE=$(curl http://localhost:$TS_PORT/cache -s -X POST -H "Accept:application/json" -H "$POST_AUTH" --data @<(cat <<EOF
            {
            "action": "get",
            "hash" : "$HASH"
            }
EOF
) | jq '."PiecesCount"')

            TORRENT_POSITION=$(curl http://localhost:$TS_PORT/cache -s -X POST -H "Accept:application/json" -H "$POST_AUTH" --data @<(cat <<EOF
            {
            "action": "get",
            "hash" : "$HASH"
            }
EOF
) | jq '."Readers"[]."Reader"')

            if [ ! -z "$(echo "$TORRENT_SIZE" | grep -o -E "[0-9]+")" ] && [ ! -z "$(echo "$TORRENT_POSITION" | grep -o -E "[0-9]+")" ]; then
                TORRENT_PROGRESS=$((($TORRENT_POSITION * 100) / $TORRENT_SIZE))
            else
                TORRENT_PROGRESS=0
            fi
            if [ $TORRENT_PROGRESS -gt $QBT_DOWNLOAD_THRESHOLD ]; then
                [ "$QBT_ADD_PAUSED" == "true" ] && export QBT_TORRENT_OPT="--paused" || export QBT_TORRENT_OPT=""
                qbt torrent add url $QBT_TORRENT_OPT "$(jq -r '."torrents"."'"$HASH"'"."url"' $TS_STAT)"
                qbt torrent tracker add $HASH $QBT_LOCAL_TRACKER
                qbt torrent options -p true -s true $HASH
                if [ "$QBT_ADD_MORE_TRACKERS" == "true" ] && [ -s "/TS/more_trackers.txt" ]; then
                    qbt torrent tracker add $HASH $(cat /TS/more_trackers.txt)
                fi
                [ "$QBT_ADD_PAUSED" != "false" ] && qbt torrent reannounce $HASH
            fi
        fi
    done
fi
