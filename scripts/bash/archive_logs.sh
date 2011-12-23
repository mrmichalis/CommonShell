#!/bin/bash

TE_BACKUPDIR=/backup/select
FTP_SERVER_IP=
FTP_REMOTE_DIR=/Select7
FTP_USERNAME=
FTP_PASSWORD=

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
  echo "$0 [--no-include-txlog] [--dry-run] [--copy] [--back-up <dir>] <age>"
  echo "Remove log files older than a certain number of days."
  echo "--no-include-txlog: Do not process TxLog files; default is to process them."
  echo "--dry-run: Just list which files would be processed, don't actually process them. Just print to stdout."
  echo "--copy: Switch only valid when '--back-up' is used. Copy instead of remove files; default is to move them."
  echo "--back-up <backup dir>: Instead for removing, move the files to a backup directory."
  echo "<days>: The age in days of files to be kept."
}

INCLUDE_TXLOG=y
NO_FTP=n
while [ "${1:0:1}" == "-" ]; do
  case $1 in
    --no-include-txlog)
      INCLUDE_TXLOG=n
      ;;
    --no-ftp)
      NO_FTP=y
      ;;
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
      BACKUP_DATE=`date "+%Y-%m-%d--%H.%M.%S"`
      BACKUP_DIR="$BACKUP_DIR" 
      ;;
    --copy)
      COPY_FILES=y
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

if [ ! -z "$COPY_FILES" ]; then
  if [ -z "$BACKUP_DIR" ]; then
  	echo "--copy used, but not --back-up."
  	showUsage
  	exit 1
  fi
fi

AGE=$1
if [ -z "$AGE" ]; then
  echo "The argument <days> is missing."
  showUsage
  exit 1
fi

test $AGE -le 0 >&/dev/null
if [ "$?" == 2 ]; then
  echo "The argument <days> is not numerical, but '$AGE'."
  showUsage
  exit 1
fi
if [ "$AGE" -le "0" ]; then
  #DATESELECT="-true"
  DATESELECT="-mtime 0"
else
  DATESELECT="-mtime +$(($AGE-1))"
fi

purge_dir() {
    if [ -e "$1/installation/install.sh" ]; then
      # An available version. Don't purge here.
      return 1;
    fi
    local BASEDIR=`basename $1`
    if [[ "$BASEDIR" = "jdk"  || "$BASEDIR" = "cfg" || "$BASEDIR" = "cmd" ]]; then
      # Don't purge here.
      return 1;
    fi
    return 0;
}

find_old_subdirs() {
  if [ "$INCLUDE_TXLOG" = "y" ]; then
    for DIR in $TXLOGDIRS; do
      local CONTENTS=`$FIND ${DIR}/`
      if [ "$CONTENTS" = "$DIR/" ]; then
        echo $DIR
      else
        if [ "$CONTENTS" = "$DIR $DIR/unsealed" ]; then
          echo $DIR
        fi
      fi
    done
  fi
}

if [ "$INCLUDE_TXLOG" = "y" ]; then
  TXLOGDIRS=`{
    for DIR in $SYSTEM_HOME/*; do
      if purge_dir "$DIR" ; then
        $FIND $DIR -daystart \( -name \*.TxLog -or -name \*.TxLog.txt \) $DATESELECT -exec dirname \{\} \;
      fi
    done
  } | uniq`
fi

find_files() {
  for DIR in $SYSTEM_HOME/*; do
    if purge_dir "$DIR" ; then
      if [ "$INCLUDE_TXLOG" = "y" ]; then
        if [ "$NO_FTP" = "n" ]; then
            $FIND $DIR -daystart -follow \( -name \*.log -and -not -name \*-FIX-*.log -and -not -name \*.TxLog -and -not -name \*.TxLog.txt -and -not -name TransactionMonitorBdx\* \) $DATESELECT -print
        else            
            $FIND $DIR -daystart -follow \( -name \*.log -or -name \*.TxLog -or -name \*.TxLog.txt -or -name TransactionMonitorBdx\* \) $DATESELECT -print
        fi
      else
        $FIND $DIR -daystart -follow -name \*.log $DATESELECT -print
      fi
    fi
  done
  # Find log files in the cmd directory.
  $FIND $SYSTEM_HOME/cmd/ -daystart \( -name \*.log -and -not -path $LOGFILE \) $DATESELECT -print
  # Find jar files in the tmp directory.
  $FIND $SYSTEM_HOME/tmp/ -daystart -name \*.jar $DATESELECT -print
  # Find persistent counter files.
  ls $SYSTEM_HOME/*/*_CounterData_* 2>/dev/null
}

list_txlog_dirs() {
  for DIR in $TXLOGDIRS; do
    echo $DIR
  done
}

parent_dirs() {
  {
    while read LINE; do
      dirname $LINE
    done
  } | sort | uniq
}

empty_dirs() {
  while read LINE; do
    if [ `basename $LINE` != "current" ]; then
      local CONTENTS=`$FIND ${LINE}/`
      if [ "$CONTENTS"  = "$LINE/" ]; then
        echo $LINE
      fi
    fi
  done
}

{
  echo "Deleting following files:"
  find_files
} >>$LOGFILE

fix_backup_dirstructure() {
  LOCAL_DIR_NAME=`dirname "$1"`
  LOCAL_BACKUP_DIR=${LOCAL_DIR_NAME/$SYSTEM_HOME/}
  LOCAL_BACKUP_DIR="${BACKUP_DIR}/${LOCAL_BACKUP_DIR}"
  mkdir -p $LOCAL_BACKUP_DIR
}

find_bdx_dirs() {
  for DIR in $SYSTEM_HOME/*; do
    if purge_dir "$DIR" ; then
      $FIND $DIR -type d -name bdx-\*
    fi
  done
}

archive_backup_folder() {

	if [ "$NO_FTP" = "y" ]; then
		echo
		echo "Archiving contents of $BACKUP_DIR into $BACKUP_DIR/$HOSTNAME.logs-$BACKUP_DATE.tar.bz2"
		echo	
		tar -c --files-from /tmp/$BACKUP_DATE.backup.lst  | pbzip2 -vc > $BACKUP_DIR/$HOSTNAME.logs-$BACKUP_DATE.tar.bz2
		echo "Archive transferred to [ $BACKUP_DIR/$HOSTNAME.logs-$BACKUP_DATE.tar.bz2 ]"
	else            
		echo
		echo "Archiving contents of $BACKUP_DIR into $HOSTNAME.backup-$BACKUP_DATE.tar.gz"
		echo	
		tar -czvf - --files-from /tmp/$BACKUP_DATE.backup.lst | ./ncftpput -u $FTP_USERNAME -p $FTP_PASSWORD -c $FTP_SERVER_IP $FTP_REMOTE_DIR/$HOSTNAME.logs-$BACKUP_DATE.tar.gz
		echo "Archive transferred to [ $FTP_SERVER_IP/$FTP_REMOTE_DIR/$HOSTNAME.logs-$BACKUP_DATE.tar.gz ]"
	fi
  
  echo
  echo "Deleting backup list [ /tmp/$BACKUP_DATE.backup.lst ]"
  rm -f /tmp/$BACKUP_DATE.backup.lst
  echo
}

if [ -z "$DRY_RUN" ]; then
  #if [ ! -z "$BACKUP_DIR" ]; then
    #mkdir -p $BACKUP_DIR
  #fi
  delete_and_echo() {  
    while read LINE ; do
      if [ -z "$BACKUP_DIR" ]; then
        echo "Deleting $LINE"
        rm -Rf "$LINE"
      else
        #fix_backup_dirstructure "$LINE"
        #echo "Moving $LINE to $LOCAL_BACKUP_DIR"
        echo "Adding $LINE to /tmp/$BACKUP_DATE.backup.lst"
        #cp -p "$LINE" "$LOCAL_BACKUP_DIR"
        echo $LINE >> /tmp/$BACKUP_DATE.backup.lst
        if [ -z "$COPY_FILES" ]; then
          echo "Deleting $LINE"
          rm -Rf "$LINE"
        fi
      fi
    done
  }
else
  delete_and_echo() {
    while read LINE ; do
      echo "Deleting $LINE"
    done
  }
fi

find_files | delete_and_echo

{
  echo
  echo
  echo "Deleting following directories:"
  find_old_subdirs
} >>$LOGFILE

find_old_subdirs | delete_and_echo

{
  echo
  echo
  echo "Deleting following empty parent directories:"
  list_txlog_dirs | parent_dirs | empty_dirs
} >>$LOGFILE

list_txlog_dirs | parent_dirs | empty_dirs | delete_and_echo

{
  echo
  echo
  echo "Deleting following empty grandparent directories:"
  list_txlog_dirs | parent_dirs | parent_dirs | empty_dirs
} >>$LOGFILE

list_txlog_dirs | parent_dirs | parent_dirs | empty_dirs | delete_and_echo

{
  echo
  echo
  echo "Deleting following empty bdx directories:"
  find_bdx_dirs | empty_dirs
} >>$LOGFILE

find_bdx_dirs | empty_dirs | delete_and_echo

archive_backup_folder


exit 0
