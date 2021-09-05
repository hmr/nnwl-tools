#!/bin/bash

# Monitor NHK News Simultaneous TV and kick downloader up
#
# ORIGIN: 2021-09-03 by hmr
#
# Requirements: cURL. jq. pgrep

TARGET_SRV="https://www3.nhk.or.jp"
TARGET_DOC="news/json16/tvnews.json"
TARGET_URL="${TARGET_SRV}/${TARGET_DOC}"

INTERVAL=15

while true
do
    RT_JSON="$(curl -s -S "${TARGET_URL}")"
    # RT_JSON="$(cat realtime.json)"

    IFS=$'\n'
    ARR=($(jq -r '.viewFlg, .title, .link' <<< "${RT_JSON}"))
    FLG=${ARR[0]}

    if [ "${FLG}" != "true" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] simultaneous bradcasting not found"
        sleep ${INTERVAL}
        continue
    fi


    LIVE_TITLE="${ARR[1]}"
    LIVE_URL="${TARGET_SRV}${ARR[2]}"

    if ! pgrep -f "${LIVE_URL}" >& /dev/null; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Live straming found: \"${LIVE_TITLE}\" at ${LIVE_URL}"
        ./get_hls_nhk_simul.bash "${LIVE_URL}" &
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] \"${LIVE_TITLE}\" is recording now"
    fi

    sleep ${INTERVAL}
done
