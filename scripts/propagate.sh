#!/bin/bash
# --------------------------------------------------------------------------
# TITLE       : propagate.sh
#
# AUTHOR      : Michalis Kongtongk
#
# SYNOPSIS    : Generic script to copy files from one host to a group of hosts
#
# VERSION     : 1.0
#
# PARAMETERS  :
#             : SOURCEFILE  = (/source_path/source_filename)
#             : TARGETDIR   = (/target_directory/)
#             : HOSTFILE    = (file that contains list of hosts) TIP: use machines.lst
# --------------------------------------------------------------------------

showUsage() {
  echo "Usage:"
  echo "$0 [sourcefile] [targetdir] [hostsfile]"
  echo "Copy files from one host to a group of hosts."
  echo "  SOURCEFILE  = (/source_path/source_filename)"
  echo "  TARGETDIR   = (/target_directory/)"
  echo "  HOSTFILE    = (file that contains list of hosts) TIP: use machines.lst"
}

if [ $# -lt 3 ]; then
    showUsage
    exit 1
fi
SOURCEFILE=$1
shift 1
TARGETDIR=$1
shift 1
HOSTFILE=$1
shift 1

if [ -f $SOURCEFILE ]; then
   echo "File found, preparing to transfer"
   while read server;    do
     if [ ! -z $server ]; then
        echo
        echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
        echo "Connected to: ${server}"
        echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
        scp -p $SOURCEFILE ${server}:$TARGETDIR
     fi
   done < $HOSTFILE
else
   echo "File $SOURCEFILE not found..."
   exit 0
fi
exit 0