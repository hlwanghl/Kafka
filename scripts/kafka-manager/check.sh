#!/bin/bash
pid=`ps -ef | grep kafka-manager | grep -v grep |grep java | awk '{print $2}'`
if [ "x$pid" = "x" ]; then
    echo "kafka-manager is not running!"
    exit 1
fi

exit 0
