#!/bin/env bash
# --------------------------------------------------------------------------
#
# 10/12/2011 Michalis
#
#
# Makes primary master slolmeprds7al01 or baslmeprds7al01 and vice versa.
#
# Functions
# isPrimaryHost                         | Check existence of the configuration files in /cfg folder
# initWorkDir                           | initialize /opt/select/housekeeping/TE copies files
# doBackup [DIR_TO_BACKUP] [FILENAME]   | creates a backup 
# updateXml                             | update ServerConfiguration.xml swapping houstnames around
# updateSystem                          | update setup_system.sh swapping houstnames around
# updateNodes                           | update te_nodes.sh swapping houstnames around
# disableCurrentPrimary                 | remove configuration files in /cfg folder
# activateNewPrimary                    | copies/scp te_nodes.sh setup_system.sh and /cfg folder to the new Primary Host
#
# --------------------------------------------------------------------------

#Globals
TIMESTAMP=`date "+%Y-%m-%d--%H.%M.%S"`
TE_DIR="/opt/select/TE"
SYS_CFG_DIR="system/cfg"
TE_WORKDIR="/opt/select/housekeeping/TE"
HOUSEKEEPING_DIR=`dirname $TE_WORKDIR`
DEST_TE_DIR="/opt/select/TE"

SYSTEM_HOSTS_SLO=("slolmeprds7al01" "slolmeprds7al02" "slolmeprds7al03" \
                  "slolmeprds7al04" "slolmeprds7al05" "slolmeprds7al06" \
                  "slolmeprds7al07" "slolmeprds7al08" "slolmeprds7al09" \
                  "slolmeprds7al10" "slolmeprds7al11")

SYSTEM_HOSTS_BAS=("baslmeprds7al01" "baslmeprds7al02" "baslmeprds7al03" \
                  "baslmeprds7al04" "baslmeprds7al05" "baslmeprds7al06" \
                  "baslmeprds7al07" "baslmeprds7al08" "baslmeprds7al09" \
                  "baslmeprds7al10" "baslmeprds7al11")

SYSTEM_HOSTS_DUH=("dummyhost01" "dummyhost02" "dummyhost03" \
                  "dummyhost04" "dummyhost05" "dummyhost06" \
                  "dummyhost07" "dummyhost08" "dummyhost09" \
                  "dummyhost10" "dummyhost11")

SYSTEM_HOSTS_DOMAIN="lme.co.uk"

THIS_HOST=`hostname | sed s/\\\..\*//g`
case $THIS_HOST in
  IT004950*)
    rm -Rf /opt/select/housekeeping/TE
    rm -Rf /opt/select/TE
    unzip TE_SLO.zip -d /opt/select
    NEW_PRIMARY_HOST="root@10.83.53.194"
    echo "Primary Host will be $NEW_PRIMARY_HOST"
  ;;
  slolmeprds7al01*)
    NEW_PRIMARY_HOST="baslmeprds7al01"
    echo "Primary Host will be $NEW_PRIMARY_HOST"
  ;;
  baslmeprds7al01*)
    NEW_PRIMARY_HOST="slolmeprds7al01"
    echo "Primary Host will be $NEW_PRIMARY_HOST"
  ;;
  *)
    echo "Invalid host $HOSTNAME. Execute from either [slolmeprds7al01] or [baslmeprds7al01] ..."
    exit 1
  ;;
esac

# Verify that this is the current Primary
isPrimaryHost(){
  local -ar CURR_CFG_FILES=("$SYS_CFG_DIR/FwConfiguration.xml" "$SYS_CFG_DIR/hostsInConfig.txt" \
                          "$SYS_CFG_DIR/OverrideConfiguration.xml" "$SYS_CFG_DIR/ServerConfiguration.xml" \
                          "setup_system.sh" "te_nodes.sh")
  for f in ${CURR_CFG_FILES[@]}; do
    if [ ! -e "$TE_DIR/$f" ]; then
      echo "$TE_DIR/$f does not exist."
      echo "This script should be executed on the Current Primary!"
      exit 1
    fi
  done

  if [ ! -d "$TE_DIR/$SYS_CFG_DIR/xsd" ]; then
      echo "$TE_DIR/$SYS_CFG_DIR/xsd does not exist."
      echo "This script should be executed on the Current Primary!"
      exit 1
  fi
}

doBackup(){
  if [[ $# -eq 2 ]]; then
    echo
    echo "Archiving $1 into $HOUSEKEEPING_DIR/$2.tar.gz"
    pushd $1 >&/dev/null
    tar czvf $HOUSEKEEPING_DIR/$2.tar.gz * >&/dev/null
    popd >&/dev/null
    echo
  else
    echo "Missing arguments ..."
    echo "doBackup [DIR_TO_BACKUP] [FILENAME]"
  fi
}

initWorkDir(){
  local -ar TE_CFG_DIRS=("xsd" "dbproducts")
  local -ar TE_CFG_FILES=("$SYS_CFG_DIR/dbproducts/mysql.xml" "$SYS_CFG_DIR/dbproduct.xml" \
                        "$SYS_CFG_DIR/dbProductLibs.txt"  "$SYS_CFG_DIR/FwConfiguration.xml" \
                        "$SYS_CFG_DIR/hostsInConfig.txt" "$SYS_CFG_DIR/OverrideConfiguration.xml" \
                        "$SYS_CFG_DIR/ServerConfiguration.xml" "setup_system.sh" "te_nodes.sh")
  #we don't need old data
  if [ -d $TE_WORKDIR/$SYS_CFG_DIR ]; then
    rm -Rf $TE_WORKDIR/$SYS_CFG_DIR
  fi
  for d in ${TE_CFG_DIRS[@]}; do
    mkdir -p $TE_WORKDIR/$SYS_CFG_DIR/$d
  done
  for f in ${TE_CFG_FILES[@]}; do
    cp $TE_DIR/$f $TE_WORKDIR/$f
  done
  cp -r $TE_DIR/$SYS_CFG_DIR/xsd $TE_WORKDIR/$SYS_CFG_DIR
}

updateXml(){
  local -r out=$TE_WORKDIR/$SYS_CFG_DIR/ServerConfiguration.xml
  local -i h=0
  echo "Updating ServerConfiguration.xml ..."
  for d in {0..21}; do
    if [ $(( $d % 2 )) -ne 0 ]; then
      TEMP=$(cat $out | sed "s/\"${SYSTEM_HOSTS_SLO[$h]}.${SYSTEM_HOSTS_DOMAIN}\"/\"T_${SYSTEM_HOSTS_DUH[$h]}.${SYSTEM_HOSTS_DOMAIN}\"/g" | sed "s/\"${SYSTEM_HOSTS_SLO[$h]}-app.${SYSTEM_HOSTS_DOMAIN}\"/\"T_${SYSTEM_HOSTS_DUH[$h]}-app.${SYSTEM_HOSTS_DOMAIN}\"/g")
      BAS_SLO=$(echo "$TEMP" | sed "s/\"${SYSTEM_HOSTS_BAS[$h]}.${SYSTEM_HOSTS_DOMAIN}\"/\"${SYSTEM_HOSTS_SLO[$h]}.${SYSTEM_HOSTS_DOMAIN}\"/g" | sed "s/\"${SYSTEM_HOSTS_BAS[$h]}-app.${SYSTEM_HOSTS_DOMAIN}\"/\"${SYSTEM_HOSTS_SLO[$h]}-app.${SYSTEM_HOSTS_DOMAIN}\"/g")
      echo "$(echo "$BAS_SLO" | sed "s/\"T_${SYSTEM_HOSTS_DUH[$h]}.${SYSTEM_HOSTS_DOMAIN}\"/\"${SYSTEM_HOSTS_BAS[$h]}.${SYSTEM_HOSTS_DOMAIN}\"/g" | sed "s/\"T_${SYSTEM_HOSTS_DUH[$h]}-app.${SYSTEM_HOSTS_DOMAIN}\"/\"${SYSTEM_HOSTS_BAS[$h]}-app.${SYSTEM_HOSTS_DOMAIN}\"/g")" > $out
      ((h+=1))
    fi
  done
}

updateSHFiles(){
  local -ar CURR_SH_FILES=("setup_system.sh" "te_nodes.sh")
  local -i h=0  
  for out in ${CURR_SH_FILES[@]}; do
    echo "Updating $out ..."
    ((h=0))
    for d in {0..21}; do
      if [ $(( $d % 2 )) -ne 0 ]; then
        TEMP=$(cat "$TE_WORKDIR/$out" | sed "s/${SYSTEM_HOSTS_SLO[$h]}/T_${SYSTEM_HOSTS_DUH[$h]}/g")
        BAS_SLO=$(echo "$TEMP" | sed "s/${SYSTEM_HOSTS_BAS[$h]}/${SYSTEM_HOSTS_SLO[$h]}/g")
        echo "$(echo "$BAS_SLO" | sed "s/T_${SYSTEM_HOSTS_DUH[$h]}/${SYSTEM_HOSTS_BAS[$h]}/g")" > $TE_WORKDIR/$out ; ((h+=1))
      fi
    done
  done
}

disableCurrentPrimary(){
  local -ar CURR_CFG_FILES=("$SYS_CFG_DIR/FwConfiguration.xml" "$SYS_CFG_DIR/hostsInConfig.txt" \
                          "$SYS_CFG_DIR/OverrideConfiguration.xml" "$SYS_CFG_DIR/ServerConfiguration.xml" \
                          "setup_system.sh" "te_nodes.sh")
  echo
  echo "Removing files configuration files from $THIS_HOST ..."
  for f in ${CURR_CFG_FILES[@]}; do
    echo " Removing '$TE_DIR/$f'"
    rm -f $TE_DIR/$f
  done

  if [ -d $TE_DIR/$SYS_CFG_DIR/xsd ]; then
    echo " Removing recursively $TE_DIR/$SYS_CFG_DIR/xsd"
    rm -Rf $TE_DIR/$SYS_CFG_DIR/xsd
  fi
}

activateNewPrimary(){
  local -ar TE_CFG_DIRS=("xsd" "dbproducts")
  local -ar CURR_SH_FILES=("setup_system.sh" "te_nodes.sh")

  echo " Staging $HOUSEKEEPING_DIR folder on $NEW_PRIMARY_HOST ..."
  ssh $NEW_PRIMARY_HOST "mkdir -p $HOUSEKEEPING_DIR"
  for d in ${TE_CFG_DIRS[@]}; do
    echo " Staging $DEST_TE_DIR/$SYS_CFG_DIR/$d folder on $NEW_PRIMARY_HOST ..."
    ssh $NEW_PRIMARY_HOST "mkdir -p $DEST_TE_DIR/$SYS_CFG_DIR/$d"
  done

  #Propagate new setup_system.sh and te_nodes.sh
  echo
  echo "Configuring $NEW_PRIMARY_HOST to become primary host..."
  for f in ${CURR_SH_FILES[@]}; do
    echo
    echo " Copying new $f from $TE_WORKDIR/ into $TE_DIR/$f ..."
    cp $TE_WORKDIR/$f $TE_DIR/$f
    for node in ${SYSTEM_HOSTS_SLO[@]}; do
      if [ $THIS_HOST != $node ]; then
        echo "  scp $TE_WORKDIR/$f $node:$DEST_TE_DIR/$f"
        scp $TE_WORKDIR/$f $node:$DEST_TE_DIR/$f
      fi
    done
    for node in ${SYSTEM_HOSTS_BAS[@]}; do
      if [ $THIS_HOST != $node ]; then
        echo "  scp $TE_WORKDIR/$f $node:$DEST_TE_DIR/$f"
        scp $TE_WORKDIR/$f $node:$DEST_TE_DIR/$f
      fi
    done
  done

  echo " scp $HOUSEKEEPING_DIR/$THIS_HOST-$NEW_PRIMARY_HOST-$TIMESTAMP.tar.gz $NEW_PRIMARY_HOST:$HOUSEKEEPING_DIR/$THIS_HOST-$NEW_PRIMARY_HOST-$TIMESTAMP.tar.gz"
  scp $HOUSEKEEPING_DIR/$THIS_HOST-$NEW_PRIMARY_HOST-$TIMESTAMP.tar.gz $NEW_PRIMARY_HOST:$HOUSEKEEPING_DIR/$THIS_HOST-$NEW_PRIMARY_HOST-$TIMESTAMP.tar.gz
  echo " ssh $NEW_PRIMARY_HOST "tar xvf $HOUSEKEEPING_DIR/$THIS_HOST-$NEW_PRIMARY_HOST-$TIMESTAMP.tar.gz -C $DEST_TE_DIR""
  ssh $NEW_PRIMARY_HOST "tar xvf $HOUSEKEEPING_DIR/$THIS_HOST-$NEW_PRIMARY_HOST-$TIMESTAMP.tar.gz -C $DEST_TE_DIR"
  echo "TODO: Modify the Cronjobs on $NEW_PRIMARY_HOST ... "
  echo "$NEW_PRIMARY_HOST is now Primary"
}

#set -x
isPrimaryHost
initWorkDir
  doBackup "$TE_WORKDIR" "$THIS_HOST-backup-$TIMESTAMP"
updateXml
updateSHFiles
  doBackup "$TE_WORKDIR" "$THIS_HOST-$NEW_PRIMARY_HOST-$TIMESTAMP"
disableCurrentPrimary
#activateNewPrimary
#set +x
