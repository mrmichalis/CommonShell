#!/bin/env bash
# --------------------------------------------------------------------------
# TITLE         : safestart.sh
#
# AUTHOR        : Michalis
#
# SYNOPSIS      : Generic script to start a process and dump it's PID into a file
#
# VERSION       : 1.0
#
# PARAMETERS    :
#               : PIDFILE = (/source_path/source_filename)
#               : COMMAND = (/target_directory/)
# --------------------------------------------------------------------------

if [ $# -lt 2 ]; then
    echo "usage: $0 [pidfile] [command]" 1>&2
    exit 1
fi

PIDFILE=$1
shift 1
COMMAND=$1
shift 1

#check pid file for process
if [ -a $PIDFILE ]; then
    c=$(ps -p $(cat $PIDFILE) | wc -l)
    if [ $c -eq 2 ]; then
        echo 'already running' 1>&2
        ls -l $PIDFILE 1>&2
        exit 1
    fi
fi

#dump pid
echo "$$" > $PIDFILE 
chmod 666 $PIDFILE >/dev/null 2>&1
#run command
$COMMAND "$@"

#remove pid file
rm $PIDFILE