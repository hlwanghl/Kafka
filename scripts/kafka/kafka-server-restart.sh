#!/bin/bash
kafka_pid=$(ps -ef  | grep  kafka |grep -v grep |grep java | awk '{print $2}')
if [ "x$kafka_pid" = "x" ]; then
    echo "kafka is not running!"
    exit 0
else
  kill -s TERM $kafka_pid
# Check if kafka server  is terminated
  for i in $(seq 0 5); do
     if ! ps -ef | grep Kafka | grep java | grep -v grep > /dev/null; then
         echo "kafka server  is successfully terminated" 1>&2
         exit 0
     fi
     sleep 1
  done
# do kill kafka server
 kill -9 $kafka_pid
fi
/opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/server.properties
sleep 3s
for i in $(seq 0 120); do
     if  ps -ef | grep kafka |grep java |grep -v grep; then
        exit 0
    fi
    sleep 1
 done
 echo "fail to restart kafka server!"
 exit 1

