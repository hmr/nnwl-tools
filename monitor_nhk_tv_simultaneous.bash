#!/bin/bash

# Monitor NHK News Simultaneous TV and kick downloader up
#
# ORIGIN: 2021-09-03 by hmr
#
# Requirements: cURL. jq. pgrep

TARGET_SRV="https://www3.nhk.or.jp"
TARGET_DOC="news/json16/tvnews.json"
TARGET_URL="${TARGET_SRV}/${TARGET_DOC}"

INTERVAL=60

while true
do
    # サイマル放送情報のJSONを取得
    RT_JSON="$(curl -s -S "${TARGET_URL}")"

    # JSONからサイマル放送のフラグ、タイトル、リンクを取得
    IFS=$'\n'
    ARR=($(jq -r '.viewFlg, .title, .link' <<< "${RT_JSON}"))
    FLG=${ARR[0]}

    # サイマル放送が実施されているか判定
    if [ "${FLG}" != "true" ]; then
        # 実施されていないので待機
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] simultaneous bradcasting not found"
        sleep ${INTERVAL}
        continue
    fi

    # サイマル放送が実施されている
    LIVE_TITLE="${ARR[1]}"
    LIVE_URL="${TARGET_SRV}${ARR[2]}"

    # すでに録画を開始しているか判定
    if ! pgrep -f "${LIVE_URL}" >& /dev/null; then
        # 録画プログラムを呼び出す
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] simultaneous broadcasting found: \"${LIVE_TITLE}\" at ${LIVE_URL}"
        ./get_hls_nhk_simul.bash "${LIVE_URL}" &
    else
        # 録画中であることを通知
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] \"${LIVE_TITLE}\" is recording now"
    fi

    sleep ${INTERVAL}
done
