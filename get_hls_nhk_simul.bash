#!/bin/bash

# Download NHK Newa Simulteneous broadcasting streaming.

# Origin 2021-08-26 by hmr

# Required softwares: GNU sed, GNU grep, cURL, jq

function decho() {
    if [ "${DEBUG}" -ne 0 ]; then
        printf '[debug] %s\n' "$1"
    fi
}

if [ -n "${ZSH_VERSION}" ]; then
    setopt -o KSH_ARRAYS
fi

# Check argument(s)
if [ $# -lt 1 ]; then
    echo "Too few arguments."
    echo "Usage: $0 <URL>"
    exit 1
fi

set -eu

DEBUG=1
OUT_DIR_PREFIX="out"

PAGE_URL=$1
echo "PAGE_URL=${PAGE_URL}"

# Check URL
echo -n "Checking URL..."
if ! echo "${PAGE_URL}" | grep -q "nhk"; then
    echo "[Error] Looks not NHK News Live URL"
    exit 2
fi

if ! echo "${PAGE_URL}" | grep -qP "\.html$"; then
    echo "[Error] Looks not NHK News Live URL"
    exit 2
fi

if curl -output /dev/null --silent --head --fail "${PAGE_URL}"; then
    echo "looks good!"
else
    echo "[Error] URL doesn't exist!"
    exit 2
fi

# Extract from given URL
URL_SERVER="$(echo "${PAGE_URL%/*}" | cut -d '/' -f 1-3)"
decho "URL_SERVER=${URL_SERVER}"
URL_PREFIX="${PAGE_URL%/*}"
decho "URL_PREFIX=${URL_PREFIX}"
URL_PREFIX_PLAYER="${URL_PREFIX}/movie"
decho "URL_PREFIX_PLAYER=${URL_PREFIX_PLAYER}"

# # 生中継番号を作成する
# LIVE_NUM="tv$(date +'%Y%m%d-%H%M%S')"
# decho "LIVE_NUM=${LIVE_NUM}"
#
# OUT_DIR="${OUT_DIR_PREFIX}/${LIVE_NUM}"
# # 出力ディレクトリを作成できなかったらエラー
# if ! mkdir "${OUT_DIR}"; then
#     echo "[Error] Can't make output directory. [${OUT_DIR}]"
#     exit 3
# fi
# decho "OUT_DIR=${OUT_DIR}"

# Player JSON の URL
PLAYER_JSON_URL="${URL_PREFIX_PLAYER}/player_live.json"
decho "PLAYER_JSON_URL=${PLAYER_JSON_URL}"

# Player JSON を取得
PLAYER_JSON_FILE=$(curl -s -S "${PLAYER_JSON_URL}")

# Player JSON から日付情報を抜き出し、日本時間に変換後、ライブ番号として使用 'tv20210531_102450'
LIVE_NUM="tv$(date -d "$(jq -r '.va.adobe.vodContentsID.VInfo3' <<<"${PLAYER_JSON_FILE}")" +'%Y%m%d_%H%M%S')"
decho "LIVE_NUM=${LIVE_NUM}"

# 出力ディレクトリを作成できなかったらエラー
OUT_DIR="${OUT_DIR_PREFIX}/${LIVE_NUM}"
if ! mkdir "${OUT_DIR}"; then
    echo "[Error] Can't make output directory. [${OUT_DIR}]"
    exit 3
fi
decho "OUT_DIR=${OUT_DIR}"

if [ "${DEBUG}" -ne 0 ]; then
    # Player JSONを保存
    echo "${PLAYER_JSON_FILE}" > "${OUT_DIR}/player_live.json"
    decho "Player JSON saved as '${OUT_DIR}/player_live.json'"
fi

# HLS プレイリスト(.m3u8) の URL を Player JSON から抽出
HLS_PL_URL="$(jq -r ".mediaResource.url" <<<"${PLAYER_JSON_FILE}")"
decho "HLS_PL_URL=${HLS_PL_URL}"

# HLS プレイリストを取得
HLS_PL_FILE=$(curl -s -S "${HLS_PL_URL}")
if [ "${DEBUG}" -ne 0 ]; then
    # HLS プレイリストを保存
    echo "${HLS_PL_FILE}" > "${OUT_DIR}/playlist.m3u8"
    decho "HLS Playlist saved as '${OUT_DIR}/playlist.m3u8'"
fi

# ストリームのプレイリスト(.m3u8)の URL を HLS プレイリストから抽出
STREAM_SERVER="$(echo "${HLS_PL_URL}" | cut -d '/' -f 1-3)"
STREAM_PL_URL="${STREAM_SERVER}$(grep 'master-512k.m3u8' <<<"${HLS_PL_FILE}")"
# 念のため改行コードを削除
STREAM_PL_URL=$(echo "$STREAM_PL_URL" | sed -z -e 's/\r\n//g' -e 's/\r//g' -e 's/\n//g')
decho "STREAM_PL_URL=${STREAM_PL_URL}"

# 出力ファイル名
TITLE="$(jq -r '.va.adobe.vodContentsID.VInfo1' <<<"${PLAYER_JSON_FILE}")" # "ニュース同時提供"
# FILE_PREFIX="$(date +'%Y%m%d_%H%M%S')-nhk-${LIVE_NUM}-${TITLE}"
FILE_PREFIX="${LIVE_NUM}-${TITLE}" # 'tv20210531_102450-ニュース同時提供'
OUT_FILE="${FILE_PREFIX}.mp4"
LOG_FILE="${FILE_PREFIX}.log"
decho "OUT_FILE=${OUT_FILE}"
decho "LOG_FILE=${LOG_FILE}"

# Download the stream
echo
ffmpeg -loglevel level+warning \
    -i "${STREAM_PL_URL}" \
    -c copy \
    -bsf:a aac_adtstoasc \
    -f mp4 \
    -y \
    "${OUT_DIR}/${OUT_FILE}" \
    >& "${OUT_DIR}/${LOG_FILE}"