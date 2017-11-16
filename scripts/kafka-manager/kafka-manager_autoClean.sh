delete_cluster=$(curl http://metadata/self/deleting-host -s)
if [[ "$delete_cluster" =~ "Not found" ]]
then
zkConect=$(cat /opt/kafka/config/server.properties |grep zookeeper.connect= |awk -F = '{print $2}')
zk=`echo $zkConect |awk -F / '{print $1}'`
nameSpace=`echo $zkConect |awk -F / '{print $2}'`
cluster_id=`echo $zkConect |awk -F / '{print $3}'`
/opt/zookeeper/bin/zkCli.sh  -server ${zk} rmr /kafka-manager/configs/${cluster_id}
/opt/zookeeper/bin/zkCli.sh -server ${zk} quit
 else 
       exit 0
fi
