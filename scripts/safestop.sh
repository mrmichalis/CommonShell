#!/bin/bash
# --------------------------------------------------------------------------
# TITLE : safestop.sh
#
# AUTHOR : Michalis Kongtongk
#
# SYNOPSIS : Generic script to stop a process from it's PID into a file
#
# VERSION : 1.0
#
# PARAMETERS :
# : PIDFILE = (/source_path/source_filename)
# --------------------------------------------------------------------------

SLEEP=5
if [ $# -lt 1 ]; then
    echo "usage: $0 [pidfile] --force" 1>&2
    exit 1
fi

PIDFILE=$1
shift 1
FORCE=$1
shift 1

if [ ! -z "$PIDFILE" ]; then
  if [ -f "$PIDFILE" ]; then
    if [ -s "$PIDFILE" ]; then
      kill -0 `cat "$PIDFILE"` >/dev/null 2>&1
      if [ $? -gt 0 ]; then
        echo "PID file found but no matching process was found. Stop aborted."
		rm -f $PIDFILE
        exit 1
      fi
    else
      echo "PID file is empty and has been ignored."
    fi
  else
    echo "$PIDFILE was set but the specified file does not exist. Is Process running? Stop aborted."
    exit 1
  fi
fi

if [ ! -z "$PIDFILE" ]; then
  if [ -f "$PIDFILE" ]; then
    while [ $SLEEP -ge 0 ]; do
      kill -0 `cat "$PIDFILE"` >/dev/null 2>&1
      if [ $? -gt 0 ]; then
        rm -f "$PIDFILE" >/dev/null 2>&1
        if [ $? != 0 ]; then
          if [ -w "$PIDFILE" ]; then
            cat /dev/null > "$PIDFILE"
          else
            echo "Process stopped but the PID file could not be removed or cleared."
          fi
        fi
        break
      fi
      if [ $SLEEP -gt 0 ]; then
        sleep 1
      fi
      if [ $SLEEP -eq 0 ]; then
        if [ -z "$FORCE" ]; then
          echo "Process did not stop in time. PID file was not removed."
        fi
      fi
      SLEEP=`expr $SLEEP - 1 `
    done
  fi
fi
  
if [ "$FORCE" = "--force" ]; then
    if [ -z "$PIDFILE" ]; then
      echo "Kill failed: \$PIDFILE not set"
    else
      if [ -f "$PIDFILE" ]; then
        PID=`cat "$PIDFILE"`
        echo "Killing Process with the PID: $PID"
        kill -9 $PID
		ps ax | grep "java"| grep -v grep | awk '{print $1}' | xargs -i kill -9 {} 2&>/dev/null
        rm -f "$PIDFILE" >/dev/null 2>&1
        if [ $? != 0 ]; then
          echo "Process $PID was killed but the PID file could not be removed."
        fi
      fi
    fi
fi