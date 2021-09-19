#!/bin/bash
# Common functions for nnwl-tools

# ORIGIN: 2021-09-19 by hmr

PROG_CHECK_NHK_NEWS_LIVE="./check_nhk_news_live.bash"
PROG_CHECK_NHK_TV_SIMUL="./check_nhk_tv_simul.bash"

PROG_GET_NHK_NEWS_LIVE_HLS="./get_nhk_news_live_hls.bash"
PROG_GET_NHK_TV_SIMUL_HLS="./get_nhk_tv_simul_hls.bash"

PROG_FFMPEG_BIN="ffmpeg"
PROG_PGREP_BIN="pgrep"
PROG_CURL_BIN="curl"

# ログ用に日付を出力
function logdate() {
    date +'%Y-%m-%d %H:%M:%S'
}

# ログメッセージを出力
function printl() {
    local LEVEL
    if [[ "$#" -lt "2" ]]; then
        LEVEL="info"
    else
        LEVEL="$1"
        shift
    fi

    printf '[%s][%s] %s\n' "$(logdate)" "${LEVEL}" "$*"
}

# デバッグメッセージを出力
function decho() {
    if [ "${DEBUG}" -ne 0 ]; then
        printl "debug" "$@"
    fi
}

# エラーメッセージを出力
function eecho() {
    printl "error" "$@"
}

# print an informational message
function iecho() {
    printl "info" "$@"
}

# Zsh用のワークアラウンド
if [ -n "${ZSH_VERSION}" ]; then
    setopt -o KSH_ARRAYS
fi

