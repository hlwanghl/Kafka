#!/bin/bash
pid=`ps -ef | grep kafka-manager | grep -v grep |grep java  | awk '{print $2}'`
if [ "x$pid" = "x" ]; then
    echo "Trying to start kafka-manager..."
  rm -rf /opt/kafka-manager/RUNNING_PID
  nohup /opt/kafka-manager/bin/kafka-manager -Dconfig.file=/opt/kafka-manager/conf/application.conf >/data/kafka-manager.log 2>&1 &
  for i in $(seq 0 30); do
       if  ps -ef | grep kafka-manager |grep -v grep |grep java; then
          break
      fi
      sleep 1
   done
fi
