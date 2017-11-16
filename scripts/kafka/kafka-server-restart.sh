#!/bin/bash
#KAFKA_HEAP_USE="-Xms1G -Xmx1G"
#MEM_M=$(curl http://metadata/self/host/memory -s)
#MEM_M_SIZE=`expr $MEM_M / 2`
#MEM_G_SIZE=`expr $MEM_M / 2048`
#ip=$(curl http://metadata/self/host/ip -s)
#if [ ${MEM_M_SIZE} -lt 1024 ]; then 
#    KAFKA_HEAP_USE="-Xms${MEM_M_SIZE}M -Xmx${MEM_M_SIZE}M"
#elif [ ${MEM_G_SIZE} -lt 5 ]; then
#        KAFKA_HEAP_USE="-Xms${MEM_G_SIZE}G -Xmx${MEM_G_SIZE}G"
#else                               
#        KAFKA_HEAP_USE="-Xms5G -Xmx5G"

#fi
ulimit -n 100000
#export KAFKA_HEAP_OPTS="${KAFKA_HEAP_USE}"
export JMX_PORT="9999"
export LOG_DIR="/data/kafka/logs"
#export KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false  -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=$ip"
export KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:/opt/kafka/config/log4j.properties"
/opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/server.properties

