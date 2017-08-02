#! /bin/bash
  PIDS=`ps ax | grep -i 'kafka\.Kafka' | grep java | grep -v grep| awk '{print $1}'`
  if [ -z "$PIDS" ]
  then
    echo "Kafka server is not running" 1>&2
    exit 0
  fi
  /opt/kafka/bin/kafka-server-stop.sh
#check
    loop=60
    force=1
    while [ "$loop" -gt 0 ]
    do
       pid=`ps ax | grep -i 'kafka\.Kafka' | grep -v kafka-manager | grep -v grep| awk '{print $1}'`
      if [ "x$pid" = "x" ]
      then
        force=0
        break
      else
        sleep 3s
        loop=`expr $loop - 1`
      fi
    done
    if [ "$force" -eq 1 ]
    then
      kill -9 $pid
    fi
    /opt/kafka/bin/kafka-start.sh
    if [ $? -eq 0 ]; then
        echo "Restart Kafka server successful"
        exit 0
      else
        echo "Failed to restart Kafka server" 1>&2
        exit 1
fi

