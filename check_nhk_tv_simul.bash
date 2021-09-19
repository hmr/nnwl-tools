#!/bin/bash

# Monitor NHK News Simultaneous TV and kick downloader up
#
# ORIGIN: 2021-09-03 by hmr
#
# Requirements: cURL. jq. pgrep

# shellcheck source=./common_func.bash
. ./common_func.bash

TARGET_SRV="https://www3.nhk.or.jp"
TARGET_DOC="news/json16/tvnews.json"
TARGET_URL="${TARGET_SRV}/${TARGET_DOC}"

# サイマル放送情報のJSONを取得
RT_JSON="$("${PROG_CURL_BIN}" -s -S "${TARGET_URL}")"

# JSONからサイマル放送のフラグ、タイトル、リンクを取得
IFS=$'\n'
ARR=($(jq -r '.viewFlg, .title, .link' <<< "${RT_JSON}"))
FLG=${ARR[0]}

# サイマル放送が実施されているか判定
if [ "${FLG}" != "true" ]; then
    # 実施されていないので待機
    iecho "simultaneous bradcasting not found"
    exit
fi

# サイマル放送が実施されている
LIVE_TITLE="${ARR[1]}"
LIVE_URL="${TARGET_SRV}${ARR[2]}"

# すでに録画を開始しているか判定
if ! "${PROG_PGREP_BIN}" -f "${LIVE_URL}" >& /dev/null; then
    # 録画プログラムを呼び出す
    iecho " simultaneous broadcasting \"${LIVE_TITLE}\" found at ${LIVE_URL}"
    "${PROG_GET_NHK_TV_SIMUL_HLS}" "${LIVE_URL}" &
else
    # 録画中であることを通知
    iecho "simultaneous broadcasting \"${LIVE_TITLE}\" is now being recorded"
fi

