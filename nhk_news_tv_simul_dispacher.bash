#!/bin/bash

# Kicks NHK News simulteneous broadcasting monitor up periodically
#
# ORIGIN: 2021-09-19 by hmr

# shellcheck source=./common_func.bash
. ./common_func.bash

INTERVAL=60

while true
do
    if ! "${PROG_PGREP_BIN}" -f "${PROG_CHECK_NHK_TV_SIMUL}"; then
        "${PROG_CHECK_NHK_TV_SIMUL}" &
    fi
    sleep ${INTERVAL}
done
