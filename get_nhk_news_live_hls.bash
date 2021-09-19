#!/bin/bash

# Download NHK Live streaming.

# Origin 2021-08-26 by hmr

# Required softwares: GNU sed, GNU grep, cURL, jq

# shellcheck source=./common_func.bash
. ./common_func.bash

# 引数チェック
if [ $# -lt 1 ]; then
    echo "Too few arguments."
    echo "Usage: $0 <URL>"
    exit 1
fi

set -eu

DEBUG=1 # デバッグログを出力しない場合は0にしてください

# 出力先ディレクトリ
OUT_DIR_PREFIX="out"

PAGE_URL=$1
iecho "PAGE_URL=${PAGE_URL}"

# Check given URL
iecho "Checking URL..."
if ! echo "${PAGE_URL}" | grep -q "nhk"; then
    # NHKのURKではなさそう
    eecho "Looks none-nhk url"
    exit 2
fi

if ! echo "${PAGE_URL}" | grep -qP "\.html$"; then
    # 正しいURLではなさそう
    eecho "Looks not valid url"
    exit 2
fi

# URLがアクセス可能か確認
if "${PROG_CURL_BIN}" --output /dev/null --silent --head --fail "${PAGE_URL}"; then
    iecho "looks good!"
else
    eecho "URL doesn't exist!"
    exit 2
fi

DATE_PREFIX="$(date +'%Y%m%d_%H%M%S')"

# 引数のURLから抽出
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

### JSON1->PLAYER_HTML->PLAYER_JSON->HLS_PLの順で取得・抽出する

# Extract Live page JSON URL
JSON1_URL="${URL_PREFIX}/${LIVE_NUM}.json"
decho "JSON1_URL=$JSON1_URL"

# Fetch Live page JSON
JSON1=$("${PROG_CURL_BIN}" -s -S "${JSON1_URL}")

# Extract Title and Player page URL from Live page JSON
IFS=$'\n'
# shellcheck disable=SC2207
TMP_JQ_ARR=($(jq -r ".title,.stream[].videoMix" <<<"${JSON1}"))
# shellcheck disable=SC2001
TITLE=$(echo "${TMP_JQ_ARR[0]}" | sed -e 's/[[:space:]]\{1,\}/_/g')
PLAYER_HTML_URL="${URL_SERVER}${TMP_JQ_ARR[1]}"
decho "TITLE=${TITLE}"
decho "PLAYER_HTML_URL=${PLAYER_HTML_URL}"

# 出力ディレクトリ形式は「rt0001234-放送タイトル」
OUT_DIR="${OUT_DIR_PREFIX}/${LIVE_NUM}-${TITLE}"

# 出力ディレクトリを作成できなかったら通し番号を付加する
CT=0
while ! mkdir "${OUT_DIR}" >& /dev/null
do
    echo "[Error] Can't make output directory. [${OUT_DIR}]"
    ((CT++))
    OUT_DIR="${OUT_DIR_PREFIX}/${LIVE_NUM}_${CT}-${TITLE}"
done
decho "OUT_DIR=${OUT_DIR}"

JSON1_FILE="${OUT_DIR}/main.json"
[[ "${DEBUG}" -ne 0 ]] && echo "${JSON1}" > "${JSON1_FILE}" # デバッグ設定時保存
decho "JSON1_FILE=${JSON1_FILE}"

# Fetch Player page HTML
PLAYER_HTML_FILE="${OUT_DIR}/player.html"
"${PROG_CURL_BIN}" -s -S "${PLAYER_HTML_URL}" -o "${PLAYER_HTML_FILE}"
decho "PLAYER_HTML_FILE=${PLAYER_HTML_FILE}"

# Extract Player page JSON URL from Player page HTML
PLAYER_JSON_URL="${URL_PREFIX_PLAYER}/$(grep -Po "player_.*\.json" "${PLAYER_HTML_FILE}")"
decho "PLAYER_JSON_URL=${PLAYER_JSON_URL}"

# Fetch Player page JSON
PLAYER_JSON_FILE="${OUT_DIR}/player.json"
"${PROG_CURL_BIN}" -s -S "${PLAYER_JSON_URL}" -o "${PLAYER_JSON_FILE}"
decho "PLAYER_JSON_FILE=${PLAYER_JSON_FILE}"

# Extract HLS Playlist URL from Player page JSON
HLS_PL_URL="$(jq -r ".mediaResource.url" "${PLAYER_JSON_FILE}")"
decho "HLS_PL_URL=${HLS_PL_URL}"

# Fetch HLS Playlist
HLS_PL_FILE="${OUT_DIR}/playlist.m3u8"
"${PROG_CURL_BIN}" -s -S "${HLS_PL_URL}" -o "${HLS_PL_FILE}"
decho "HLS_PL_FILE=${HLS_PL_FILE}"

# Extract Stream playlist URL from HLS Playlist
STREAM_SERVER="$(echo "${HLS_PL_URL}" | cut -d '/' -f 1-3)"
# STREAM_PL_URL="https://nhknewsreal.akamaized.net$(grep 'master-512k.m3u8' "${HLS_PL_FILE}")"
STREAM_PL_URL="${STREAM_SERVER}$(grep 'master-512k.m3u8' "${HLS_PL_FILE}")"
decho "STREAM_PL_URL=${STREAM_PL_URL}"

# Output file name
FILE_PREFIX="${DATE_PREFIX}-nhk-${LIVE_NUM}-${TITLE}"
OUT_FILE="${FILE_PREFIX}.mp4"
LOG_FILE="${FILE_PREFIX}.log"
decho "OUT_FILE=${OUT_FILE}"
decho "LOG_FILE=${LOG_FILE}"

# Download the stream
echo
"${PROG_FFMPEG_BIN}" -loglevel level+warning \
    -i "${STREAM_PL_URL}" \
    -c copy \
    -bsf:a aac_adtstoasc \
    -f mp4 \
    -y \
    "${OUT_DIR}/${OUT_FILE}" \
    >& "${OUT_DIR}/${LOG_FILE}"

