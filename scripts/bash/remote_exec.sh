#!/usr/bin/env bash
SMART_HOSTS=$(awk 'BEGIN{FS="@"}{print $2}' < "$HOME/machines.lst")

# remove username from username@node
# nodeonly=${1/*@/}

doit(){
echo $host
if [ -z "$sequential" ]; then
  ssh $host "$*" 2>&1 | sed -e 's/^/'$host': /' &
else
  ssh $host "$*"
fi
}

stoppid(){
for p in $pids; do
  kill -9 $p
  echo $p killed
done
}

do_subset(){
echo "Processing $NODE_SUBLIST"
pids=
trap 'stoppid; exit' HUP INT QUIT TERM 
for host in $NODE_SUBLIST; do 
  ping $host 3 >/dev/null 2>&1
  if [ $? -ne 0 ]; then
      echo "WARNING -- No response from $host"
  else
      doit "$COMMAND"
      pids="$pids $!"
  fi
done

if [ -z "$sequential" ]; then
  echo "Await subset $pids"
  for p in $pids; do
    wait $p
    echo $p done
  done
  sleep $subset_delay
fi
}

FULL_NODE_LIST="$SMART_HOSTS"
if [ "$1" == "-h" ]; then
  shift
  eval FULL_NODE_LIST=\$$1
  shift  
fi

max_concurrent=8
if [ "$1" = "-m" ]; then
  shift;
  max_concurrent=$1
  shift;
  if [ "$max_concurrent" -le "0" ]
  then
      max_concurrent=1000000
  fi
fi

subset_delay=0
if [ "$1" = "-d" ]; then
    shift;
    subset_delay=$1
    shift;
fi

sequential=YES
if [ "$1" = "-p" ]; then
    shift;
    sequential=
fi

COMMAND="$*"
if [ -z "$COMMAND" ]; then
   echo "Usage: $0 [-h <hostname>] [-m <batch-size>] [-d <batch-delay>] [-p (executes in parallel/default sequential)] command"
   exit
fi

NODE_SUBLIST=""
cnt=0
for host in $FULL_NODE_LIST; do
  NODE_SUBLIST="$NODE_SUBLIST $host"
  let cnt=cnt+1

  if [ "$cnt" -ge "$max_concurrent" ]; then
    do_subset
    cnt=0
    NODE_SUBLIST=""
  fi
done

if [ "$cnt" -ge "0" ]; then
  do_subset
  cnt=0
fi