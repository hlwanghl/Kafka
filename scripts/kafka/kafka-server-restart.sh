#!/bin/bash
kafka_pid=$(ps -ef  | grep  kafka |grep -v grep |grep java | awk '{print $2}')
if [ "x$kafka_pid" = "x" ]; then
    echo "kafka is not running!"
    exit 0
fi
/opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/server.properties
sleep 5s
for i in $(seq 0 120); do
     if  ps -ef | grep kafka |grep java |grep -v grep; then
        exit 0
    fi
    sleep 1
 done
 echo "fail to restart kafka server!"
 exit 1
