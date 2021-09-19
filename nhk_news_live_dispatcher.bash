#!/bin/bash

# Kicks NHK News Live monitor up periodically
#
# ORIGIN: 2021-09-18 by hmr

# shellcheck source=./common_func.bash
. ./common_func.bash

INTERVAL=15

while true
do
    if ! "${PROG_PGREP_BIN}" -f "${PROG_CHECK_NHK_NEWS_LIVE}"; then
        . "${PROG_CHECK_NHK_NEWS_LIVE}" &
    fi
    sleep ${INTERVAL}
done
