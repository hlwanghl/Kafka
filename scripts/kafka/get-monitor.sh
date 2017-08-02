#!/bin/bash
nc -w 3 -z -u 127.0.0.1 8125 > /dev/null 2>&1
if [ $? -ne 0 ]
then
    echo "kafka monitor process not running"
   exit 1
 fi
   data=`echo mntr | nc -u 127.0.0.1 8125 -w 1`
   jvm_metric=`echo "$data" | grep jvm.memory.heap.usage | awk -F':' '{print $2}'`
   heap_usage=`gawk -v x=${jvm_metric} -v y=100 'BEGIN{printf "%.0f\n",x*y}'` #jvm_percent_used
   #Message.1MinuteRate
   MessagesInPerSec_1MinuteRate=`echo "$data" | grep MessagesInPerSec.1MinuteRate | awk -F':' '{print int($2)}'`
   #BytesInPerSec.1MinuteRate BytesOutPerSec.1MinuteRate
   BytesInPerSec_1MinuteRate=`echo "$data" | grep BytesInPerSec.1MinuteRate | awk -F':' '{print int($2)}'`
   BytesOutPerSec_1MinuteRate=`echo "$data" | grep BytesOutPerSec.1MinuteRate | awk -F':' '{print int($2)}'`
   #Replica.MaxLag
   Replica_MaxLag=`echo "$data" | grep Replica.MaxLag | awk -F':' '{print $2}'`
   #ReplicaManager.PartitionCozunt ReplicaManager.LeaderCount ReplicaManager.UnderReplicatedPartitions
   ReplicaManager_PartitionCount=`echo "$data" | grep ReplicaManager.PartitionCount | awk -F':' '{print $2}'`
   ReplicaManager_LeaderCount=`echo "$data" | grep ReplicaManager.LeaderCount | awk -F':' '{print $2}'`
   ReplicaManager_UnderReplicatedPartitions=`echo "$data" | grep ReplicaManager.UnderReplicatedPartitions | awk -F':' '{print $2}'`
   #IsrExpandsPerSec.1MinuteRate IsrShrinksPerSec.1MinuteRate
   IsrExpandsPerSec_1MinuteRate=`echo "$data" | grep IsrExpandsPerSec.1MinuteRate | awk -F':' '{print int($2)}'`
   IsrShrinksPerSec_1MinuteRate=`echo "$data" | grep IsrShrinksPerSec.1MinuteRate | awk -F':' '{print int($2)}'`
   #KafkaController.ActiveControllerCount KafkaController.OfflinePartitionsCount
   KafkaController_ActiveControllerCount=`echo "$data" | grep KafkaController.ActiveControllerCount | awk -F':' '{print $2}'`
   KafkaController_OfflinePartitionsCount=`echo "$data" | grep KafkaController.OfflinePartitionsCount | awk -F':' '{print $2}'`
echo "{\"heap_usage\":$heap_usage,\"MessagesInPerSec_1MinuteRate\":$MessagesInPerSec_1MinuteRate,\"BytesInPerSec_1MinuteRate\":$BytesInPerSec_1MinuteRate,\"BytesOutPerSec_1MinuteRate\":$BytesOutPerSec_1MinuteRate,\"Replica_MaxLag\":$Replica_MaxLag, \"ReplicaManager_PartitionCount\":$ReplicaManager_PartitionCount,\"ReplicaManager_LeaderCount\":$ReplicaManager_LeaderCount,\"ReplicaManager_UnderReplicatedPartitions\":$ReplicaManager_UnderReplicatedPartitions,\"IsrExpandsPerSec_1MinuteRate\":$IsrExpandsPerSec_1MinuteRate,\"IsrShrinksPerSec_1MinuteRate\":$IsrShrinksPerSec_1MinuteRate,\"KafkaController_ActiveControllerCount\":$KafkaController_ActiveControllerCount,\"KafkaController_OfflinePartitionsCount\":$KafkaController_OfflinePartitionsCount}"
