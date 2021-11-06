#!/bin/bash

# Watch NHK News Live and kick downloader up
#
# ORIGIN: 2021-08-26 by hmr

# Read common functions
. ./common_func.bash

TARGET_SRV="https://www3.nhk.or.jp"
TARGET_DOC="news/json16/realtime.json"
TARGET_URL="${TARGET_SRV}/${TARGET_DOC}"

# ライブ放送情報のJSONを取得
RT_JSON="$("${PROG_CURL_BIN}" -s -S "${TARGET_URL}")"
# RT_JSON="$(cat realtime.json)" # for development
if [[ -z "${RT_JSON}" ]]; then
	eecho "can't get document from ${TARGET_URL}"
	exit 1
fi

# 実施されているライブ放送の数を取得
NUM=$(jq -rc '.item | length' <<< "${RT_JSON}")

if [ "${NUM}" -lt 1 ]; then
    # ライブ放送が実施されていないので終了
    iecho "live streaming not found"
    exit
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
    if ! "${PROG_PGREP_BIN}" -f "${LIVE_URL}" >& /dev/null; then
        # 録画プログラムを呼び出す
        iecho "live straming \"[${LIVE_NUM}] ${LIVE_TITLE}\" found at ${LIVE_URL}"
        ${PROG_GET_NHK_NEWS_LIVE_HLS} "${LIVE_URL}" &
    else
        # 録画中であることを通知
        iecho "live streaming \"${LIVE_TITLE}\" is now being recorded"
    fi
done
