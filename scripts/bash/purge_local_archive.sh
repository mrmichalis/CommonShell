#!/bin/bash

if [ ! -z "$VERIFY" ]; then
  set -x
fi

if [ -z "$SYSTEM_HOME" ]; then
  pushd ../.. >&/dev/null
  source setup_system.sh
  popd >&/dev/null
fi

source "$SYSTEM_HOME/cmd/log_invocation.sh"
logInvocation $@

showUsage() {
  echo "Usage:"
  echo "$0 [--back-up <dir>] <age>"
  echo "Purge local log files older than a certain number of days."
  echo "--dry-run: Just list which files would be processed, don't actually process them. Just print to stdout."
  echo "--back-up <backup dir>: For removing a backup directory."
  echo "<days>: The age in days of files to be purged."
}

if [ "$1" == "" ]; then
    showUsage
    exit 1
fi

while [ "${1:0:1}" == "-" ]; do
  case $1 in
    --dry-run)
      DRY_RUN=y
      ;;
    --back-up)
      BACKUP_DIR=$2
      if [ -z "$BACKUP_DIR" ]; then
        BACKUP_DIR=$TE_BACKUPDIR
      fi
      if [ -z "$BACKUP_DIR" ]; then
        echo "No backup directory specified and TE_BACKUPDIR is undefined"
        showUsage
        exit 1
      fi
      shift
      ;;
    --help)
      showUsage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      showUsage
      exit 1
      ;;
  esac
  shift
done

AGE=$1
shift 1

if [ "$AGE" -le "0" ]; then
	DATESELECT="-mtime 0"
else
  DATESELECT="-mtime +$(($AGE-1))"
fi

find_files() {
  # Find select/backup folder exclude lost+found
  $FIND $BACKUP_DIR -daystart -maxdepth 1 \( -not -path \*lost+found \) $DATESELECT -print
}

if [ -z "$DRY_RUN" ]; then
  delete_and_echo() {
    while read LINE ; do
      echo "Deleting $LINE"
      rm -Rf "$LINE"
    done
  }
else
  delete_and_echo() {
    while read LINE ; do
      echo "Deleting $LINE"
    done
  }
fi

{
  echo "Deleting following files:"
  find_files
} >>$LOGFILE

find_files | delete_and_echo

exit 0

