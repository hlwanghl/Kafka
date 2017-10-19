#!/bin/bash
kafka_pid=`ps ax | grep -i 'kafka\.Kafka' |grep java | grep -v grep | grep -v kafka-manager| awk '{print $1}'`
if [ "x$kafka_pid" = "x" ]; then
    echo "Trying to start kafka..."
  /opt/kafka/bin/kafka-start.sh
  for i in $(seq 0 30); do
       if  ps -ef | grep kafka |grep -v kafka-manager |grep -v grep; then
          break
      fi
      sleep 1
   done
fi

manager_pid=`ps ax | grep kafka-manager | grep -v grep | awk '{print $1}'`
if [ "x$manager_pid" = "x" ]; then
    echo "Trying to start kafka-manager..."
  nohup /opt/kafka-manager/bin/kafka-manager -Dconfig.file=/opt/kafka-manager/conf/application.conf >/opt/kafka-manager/logs/kafka-manager.log 2>&1 &
  for i in $(seq 0 30); do
       if  ps -ef | grep kafka-manager |grep -v grep; then
          break
      fi
      sleep 1
   done
fi
