#!/bin/bash

KAFKA_HEAP_USE="-Xms1G -Xmx1G"
MEM_M=$(curl http://metadata/self/host/memory -s)
MEM_M_SIZE=`expr $MEM_M / 2`
MEM_G_SIZE=`expr $MEM_M / 2048`
ip=$(curl http://metadata/self/host/ip -s)
if [ ${MEM_M_SIZE} -lt 1024 ]; then #内存小于1G
    KAFKA_HEAP_USE="-Xms${MEM_M_SIZE}M -Xmx${MEM_M_SIZE}M"
elif [ ${MEM_G_SIZE} -lt 5 ]; then #大于1G小于5G
        KAFKA_HEAP_USE="-Xms${MEM_G_SIZE}G -Xmx${MEM_G_SIZE}G"
else                               #大于5G内存设置为5G
        KAFKA_HEAP_USE="-Xms5G -Xmx5G"

fi
ulimit -n 64000
export KAFKA_HEAP_OPTS="${KAFKA_HEAP_USE}"
export JMX_PORT="9999"
export  LOG_DIR="/data/kafka/logs"
export KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false  -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=$ip"
/opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/server.properties
#for i in $(seq 0 30); do
#       if  ps -ef | grep kafka |grep java |grep -v grep; then
#          break
#      fi
#      /opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/server.properties
#      sleep 2
#   done
