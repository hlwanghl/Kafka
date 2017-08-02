#!/bin/bash
KAFKA_HEAP_USE="-Xms1G -Xmx1G"
function get_mem_m_size_func(){
    local _memSize=$(($(get_mem_g_size_func)*1024))
    echo "${_memSize}"  
}

function get_mem_g_size_func(){
    local _memSize="$(dmidecode -t memory -q |grep 'Maximum Capacity' |awk -F : '{print $2}' |sed 's/^[ \t]*//g' |awk -F ' ' '{print $1;}')"
    echo "${_memSize}"
}
MEM_M_SIZE=$(($(get_mem_m_size_func)/2))
MEM_G_SIZE=$(($(get_mem_g_size_func)/2))

if [ ${MEM_M_SIZE} -lt 1024 ]; then #内存小于1G
    KAFKA_HEAP_USE="-Xms${MEM_M_SIZE}M -Xmx${MEM_M_SIZE}M"
elif [ ${MEM_G_SIZE} -lt 5 ]; then #大于1G小于5G
        KAFKA_HEAP_USE="-Xms${MEM_G_SIZE}G -Xmx${MEM_G_SIZE}G"
else                               #大于5G内存设置为5G
        KAFKA_HEAP_USE="-Xms5G -Xmx5G"

fi
ulimit -n 100000
export JAVA_HOME=/opt/jdk
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export KAFKA_HEAP_OPTS="${KAFKA_HEAP_USE}"
export JMX_PORT="9999"
ip=$(/sbin/ifconfig eth0 | grep "inet addr" | awk '{print $2}' | awk -F: '{print $2}')
export KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false  -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=$ip"
export KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:/opt/kafka/config/log4j.properties"
/opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/server.properties

