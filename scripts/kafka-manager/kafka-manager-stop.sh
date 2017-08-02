#!/bin/bash
PID_FILE="/opt/kafka-manager/RUNNING_PID"
PIDS=$(ps ax | grep -i 'kafka-manager\.kafka-manager' | grep java | grep -v grep | awk '{print $1}')

if [ -z "$PIDS" ]; then
  echo "No kafka manager to stop" 1>&2
  rm -rf $PID_FILE
  exit 0
else
  kill -s TERM $PIDS
  if [ -f $PID_FILE ]
   then
     rm $PID_FILE
  fi
fi
