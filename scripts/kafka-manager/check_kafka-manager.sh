#!/bin/bash
zkConect=$(cat /opt/kafka/config/server.properties |grep zookeeper.connect= |awk -F = '{print $2}')
cluster_id=`echo $zkConect |awk -F / '{print $3}'`
port=$(cat /opt/kafka-manager/conf/application.conf |grep http.port|awk -F = '{print $2}')
ps -fe|grep kafka |grep -v grep |grep -v kafka-manager
if [ $? -ne 0 ]
then
 /opt/kafka-manager/bin/kafka-manager-stop.sh
exit 1 # kafka  is not running
else
   export JAVA_HOME=/opt/jdk
   export PATH=$JAVA_HOME/bin:$PATH
   export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
   zkConect=$(cat /opt/kafka/config/server.properties |grep zookeeper.connect= |awk -F = '{print $2}')
   zk=`echo $zkConect |awk -F / '{print $1}'`
   nameSpace=`echo $zkConect |awk -F / '{print $2}'`
   clusterIds_temp=$(/opt/zookeeper/bin/zkCli.sh -server $zk  ls /kafka-manager/clusters |tail -1)
   clusterIds_temp2=${clusterIds_temp//[/}
   clusterIds=${clusterIds_temp2//]/}
   OLD_IFS="$IFS"
    IFS=","
    arr=($clusterIds)
    IFS="$OLD_IFS"
    for cluster in ${arr[@]}
     do
      statu=$(curl http://127.0.0.1:$port/clusters/$cluster)
      if [[ "$statu" =~ "Ask timed out" ]]
      then
     /opt/kafka-manager/bin/kafka-manager-restart.sh
      fi
     done
fi

