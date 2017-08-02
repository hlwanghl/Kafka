#!/bin/bash
export JAVA_HOME=/opt/jdk
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
delete_cluster=$(curl http://metadata/self/deleting-host)
#if [[ "$delete_cluster" =~ "Not found" ]]
#then
zkConect=$(cat /opt/kafka/config/server.properties |grep zookeeper.connect= |awk -F = '{print $2}')
zk=`echo $zkConect |awk -F / '{print $1}'`
nameSpace=`echo $zkConect |awk -F / '{print $2}'`
cluster_id=`echo $zkConect |awk -F / '{print $3}'`
/opt/zookeeper/bin/zkCli.sh  -server ${zk} rmr /kafka-manager/configs/${cluster_id}
/opt/zookeeper/bin/zkCli.sh  -server ${zk}  quit
#   else 
#       exit 0
#fi
