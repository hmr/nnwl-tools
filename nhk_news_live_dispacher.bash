#!/bin/bash

# Kicks NHK News Live monitor up periodically
#
# ORIGIN: 2021-09-18 by hmr

# shellcheck source=./common_func.bash
. ./common_func.bash

INTERVAL=15

while true
do
    if ! pgrep -f "${PROG_CHECK_NNLIVE}"; then
        . "${PROG_CHECK_NNLIVE}" &
    fi
    sleep ${INTERVAL}
done
