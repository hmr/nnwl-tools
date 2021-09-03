#!/bin/bash

# Download NHK Live streaming.

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

# URL_SERVER="https://www3.nhk.or.jp"
# URL_PREFIX="${URL_SERVER}/news/realtime"
# URL_PREFIX_PLAYER="${URL_PREFIX}/movie"

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

if curl --output /dev/null --silent --head --fail "${PAGE_URL}"; then
    echo "looks good!"
else
    echo "[Error] URL doesn't exist!"
    # exit 2
fi

# Extract from given URL
URL_SERVER="$(echo "${PAGE_URL%/*}" | cut -d '/' -f 1-3)"
decho "URL_SERVER=${URL_SERVER}"
URL_PREFIX="${PAGE_URL%/*}"
decho "URL_PREFIX=${URL_PREFIX}"
URL_PREFIX_PLAYER="${URL_PREFIX}/movie"
decho "URL_PREFIX_PLAYER=${URL_PREFIX_PLAYER}"

# URLから生中継番号を抽出
LIVE_NUM="${PAGE_URL##*/}"
LIVE_NUM="${LIVE_NUM%.htm*}"
decho "LIVE_NUM=${LIVE_NUM}"

# 出力ディレクトリを作成できなかったらエラー
if ! mkdir "${LIVE_NUM}"; then
    echo "[Error] Can't make output directory."
    exit 3
fi
# OUT_DIR=$(mktemp -d)
OUT_DIR="${OUT_DIR_PREFIX}/${LIVE_NUM}"
decho "OUT_DIR=${OUT_DIR}"

# Extract Live page JSON URL
# JSON1_URL=${URL_PREFIX}/$(echo "${PAGE_URL}" | grep -oP '\w*.html$' | sed -e 's/\.html//g').json
JSON1_URL="${URL_PREFIX}/${LIVE_NUM}.json"
decho "JSON1_URL=$JSON1_URL"

# Fetch Live page JSON
JSON1_FILE="${OUT_DIR}/main.json"
curl -s -S "${JSON1_URL}" -o "${JSON1_FILE}"
decho "JSON1_FILE=${JSON1_FILE}"

# Extract Title and Player page URL from Live page JSON
IFS=$'\n'
TEMP_JQ=($(jq -r ".title,.stream[].videoMix" "${JSON1_FILE}"))
# TITLE="${TEMP_JQ[0]//[[:space:]]/_}"
# TEMP_JQ[0]="a b   c  d"
TITLE=$(echo "${TEMP_JQ[0]}" | sed -e 's/[[:space:]]\{1,\}/_/g')
PLAYER_HTML_URL="${URL_SERVER}${TEMP_JQ[1]}"
decho "TITLE=${TITLE}"
decho "PLAYER_HTML_URL=${PLAYER_HTML_URL}"

# Fetch Player page HTML
# PLAYER_HTML_FILE="${OUT_DIR}/player_rt0006189_01.html"
PLAYER_HTML_FILE="${OUT_DIR}/player.html"
curl -s -S "${PLAYER_HTML_URL}" -o "${PLAYER_HTML_FILE}"
decho "PLAYER_HTML_FILE=${PLAYER_HTML_FILE}"

# Extract Player page JSON URL from Player page HTML
PLAYER_JSON_URL="${URL_PREFIX_PLAYER}/$(grep -Po "player_.*\.json" "${PLAYER_HTML_FILE}")"
decho "PLAYER_JSON_URL=${PLAYER_JSON_URL}"

# Fetch Player page JSON
# PLAYER_JSON_FILE="${OUT_DIR}/player_rt0006189_01.json"
PLAYER_JSON_FILE="${OUT_DIR}/player.json"
curl -s -S "${PLAYER_JSON_URL}" -o "${PLAYER_JSON_FILE}"
decho "PLAYER_JSON_FILE=${PLAYER_JSON_FILE}"

# Extract HLS Playlist URL from Player page JSON
HLS_PL_URL="$(jq -r ".mediaResource.url" "${PLAYER_JSON_FILE}")"
decho "HLS_PL_URL=${HLS_PL_URL}"

# Fetch HLS Playlist
HLS_PL_FILE="${OUT_DIR}/playlist.m3u8"
curl -s -S "${HLS_PL_URL}" -o "${HLS_PL_FILE}"
decho "HLS_PL_FILE=${HLS_PL_FILE}"

# Extract Stream playlist URL from HLS Playlist
STREAM_SERVER="$(echo "${HLS_PL_URL}" | cut -d '/' -f 1-3)"
# STREAM_PL_URL="https://nhknewsreal.akamaized.net$(grep 'master-512k.m3u8' "${HLS_PL_FILE}")"
STREAM_PL_URL="${STREAM_SERVER}$(grep 'master-512k.m3u8' "${HLS_PL_FILE}")"
decho "STREAM_PL_URL=${STREAM_PL_URL}"

# Output file name
FILE_PREFIX="$(date +'%Y%m%d_%H%M%S')-nhk-${LIVE_NUM}-${TITLE}"
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

# Delete temporary directory
# if [ -n "${OUT_DIR}" ]; then
#     rm -rf "${OUT_DIR}"
# fi
