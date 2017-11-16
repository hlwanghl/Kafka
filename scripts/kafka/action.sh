#!/bin/bash
kafka_pid=`ps -ef  | grep kafka |grep java | grep -v grep  awk '{print $2}'`
if [ "x$kafka_pid" = "x" ]; then
    echo "Trying to start kafka..."
  /opt/kafka/bin/kafka-start.sh
  for i in $(seq 0 30); do
       if  ps -ef | grep kafka |grep java |grep -v grep; then
          break
      fi
      sleep 1
   done
fi
