#!/bin/bash
ret_val=0
kafka_pid=`ps ax | grep -i 'kafka\.Kafka' |grep java | grep -v grep | grep -v kafka-manager| awk '{print $1}'`
if [ "x$kafka_pid" = "x" ]; then
    echo "kafka is not running!"
    ret_val=$[$ret_val + 1]
fi

manager_pid=`ps ax | grep kafka-manager | grep -v grep | awk '{print $1}'`
if [ "x$manager_pid" = "x" ]; then
    echo "kafka-manager is not running!"
    ret_val=$[$ret_val + 1]
fi

exit $ret_va
