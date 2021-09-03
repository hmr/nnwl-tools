#!/bin/bash

# Watch NHK News Live and kick downloader up
#
# ORIGIN: 2021-08-26 by hmr

TARGET_SRV="https://www3.nhk.or.jp"
TARGET_DOC="news/json16/realtime.json"
TARGET_URL="${TARGET_SRV}/${TARGET_DOC}"

while true
do
    RT_JSON="$(curl -s -S "${TARGET_URL}")"
    # RT_JSON="$(cat realtime.json)"

    NUM=$(jq -rc '.item | length' <<< "${RT_JSON}")

    if [ "${NUM}" -lt 1 ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] live streaming not found"
        sleep 60
        continue
    fi

    IFS=$'\n'
    for LINE in $(jq -c '.item[] | [.title, .link]' <<< "${RT_JSON}")
    do
        [ -z "${LINE}" ] && continue

        ARR=($(jq  -r '.[]' <<< "${LINE}"))
        LIVE_TITLE="${ARR[0]}"
        LIVE_URL="${TARGET_SRV}${ARR[1]}"

        #if ! ps ax | grep "${LIVE_URL}" | grep -qv grep; then
        if ! pgrep -f "${LIVE_URL}" >& /dev/null; then
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Live straming found: \"${LIVE_TITLE}\" at ${LIVE_URL}"
            ./get_hls_nhk.bash "${LIVE_URL}" &
        else
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] \"${LIVE_TITLE}\" is recording now"
        fi
    done

    sleep 60
done
