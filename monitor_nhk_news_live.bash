#!/bin/bash

# Watch NHK News Live and kick downloader up
#
# ORIGIN: 2021-08-26 by hmr

TARGET_SRV="https://www3.nhk.or.jp"
TARGET_DOC="news/json16/realtime.json"
TARGET_URL="${TARGET_SRV}/${TARGET_DOC}"

INTERVAL=15

while true
do
    # ライブ放送情報のJSONを取得
    RT_JSON="$(curl -s -S "${TARGET_URL}")"
    # RT_JSON="$(cat realtime.json)" # for debug

    # 実施されているライブ放送の数を取得
    NUM=$(jq -rc '.item | length' <<< "${RT_JSON}")

    if [ "${NUM}" -lt 1 ]; then
        # ライブ放送が実施されていないので待機する
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] live streaming not found"
        sleep ${INTERVAL}
        continue
    fi

    # ライブ放送が実施されている
    IFS=$'\n'
    for LINE in $(jq -c '.item[] | [.title, .link]' <<< "${RT_JSON}")
    do
        [ -z "${LINE}" ] && continue

        # ライブ放送のタイトル、URL、ライブ放送番号(rt0123456形式)
        ARR=($(jq  -r '.[]' <<< "${LINE}"))
        LIVE_TITLE="${ARR[0]}"
        LIVE_URL="${TARGET_SRV}${ARR[1]}"
        LIVE_NUM="$(basename "${ARR[1]}" | sed -e 's/\.html//')"

        # すでに録画を開始しているか判定
        if ! pgrep -f "${LIVE_URL}" >& /dev/null; then
            # 録画プログラムを呼び出す
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] live straming found: \"[${LIVE_NUM}] ${LIVE_TITLE}\" at ${LIVE_URL}"
            ./get_hls_nhk.bash "${LIVE_URL}" &
        else
            # 録画中であることを通知
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] \"${LIVE_TITLE}\" is recording now"
        fi
    done

    sleep ${INTERVAL}
done
