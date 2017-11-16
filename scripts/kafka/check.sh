#!/bin/bash
kafka_pid=$(ps -ef  | grep  kafka |grep -v grep |grep java | awk '{print $2}')
if [ "x$kafka_pid" = "x" ]; then
    echo "kafka is not running!"
    exit 1
fi
exit 0
