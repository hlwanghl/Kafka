#!/usr/bin/env bash
for envFile in /opt/app/bin/*.env; do . $envFile; done

log() {
  logger -t appctl --id=$$ [cmd=$command] "$@"
}

startZabbix() {
  if [ "${ZABBIX_AGENT_ENABLE}" = "true" ]; then 
    systemctl restart zabbix-agent   
  else
    systemctl stop    zabbix-agent
  fi
}

init() {
  if [ "$MY_ROLE" = "kafka-manager" ]; then echo 'root:kafka' | chpasswd; echo 'ubuntu:kafka' | chpasswd; fi
  mkdir -p /data/zabbix  /data/$MY_ROLE/{dump,logs}
  chown -R zabbix.zabbix /data/zabbix
  chown -R kafka.kafka /data/$MY_ROLE  
  touch    /data/zabbix/zabbix_agentd.log
  chown -R zabbix.zabbix /data/zabbix/zabbix_agentd.log
  local htmlFile=/data/$MY_ROLE/index.html
  [ -e "$htmlFile" ] || ln -s /opt/app/conf/caddy/index.html $htmlFile
}


start() {
  isInitialized || init
  local svc; for svc in $(getServices -a); do initSvc $svc; done
  startZabbix
  for svc in $(getServices); do execute startSvc; done
  retry 60 1 0 execute check
  if [ "$MY_ROLE" = "kafka-manager" ]; then
    retry 60 1 0 execute checkEndpoint "tcp:${MY_PORT:-80}";
    local httpCode="$(addCluster)";
    if [ "$httpCode" != "200" ]; then log "Failed to add cluster automatically with '$httpCode'."; fi
  fi
}

addCluster() {
  . /opt/app/bin/version.env
  curl -s -m5 -w "%{http_code}" -o /dev/null \
    -u "$WEB_USER:$WEB_PASSWORD" \
    --data-urlencode "name=$CLUSTER_ID" \
    --data-urlencode "zkHosts=$ZK_HOSTS" \
    --data-urlencode "kafkaVersion=$KAFKA_VERSION" \
    --data-urlencode "jmxEnabled=true" \
    --data-urlencode "jmxUser=" \
    --data-urlencode "jmxPass=" \
    --data-urlencode "tuning.brokerViewUpdatePeriodSeconds=30" \
    --data-urlencode "tuning.clusterManagerThreadPoolSize=2" \
    --data-urlencode "tuning.clusterManagerThreadPoolQueueSize=100" \
    --data-urlencode "tuning.kafkaCommandThreadPoolSize=2" \
    --data-urlencode "tuning.kafkaCommandThreadPoolQueueSize=100" \
    --data-urlencode "tuning.logkafkaCommandThreadPoolSize=2" \
    --data-urlencode "tuning.logkafkaCommandThreadPoolQueueSize=100" \
    --data-urlencode "tuning.logkafkaUpdatePeriodSeconds=30" \
    --data-urlencode "tuning.partitionOffsetCacheTimeoutSecs=5" \
    --data-urlencode "tuning.brokerViewThreadPoolSize=2" \
    --data-urlencode "tuning.brokerViewThreadPoolQueueSize=1000" \
    --data-urlencode "tuning.offsetCacheThreadPoolSize=2" \
    --data-urlencode "tuning.offsetCacheThreadPoolQueueSize=1000" \
    --data-urlencode "tuning.kafkaAdminClientThreadPoolSize=2" \
    --data-urlencode "tuning.kafkaAdminClientThreadPoolQueueSize=1000" \
    --data-urlencode "tuning.kafkaManagedOffsetMetadataCheckMillis=30000" \
    --data-urlencode "tuning.kafkaManagedOffsetGroupCacheSize=1000000" \
    --data-urlencode "tuning.kafkaManagedOffsetGroupExpireDays=7" \
    --data-urlencode "securityProtocol=PLAINTEXT" \
    --data-urlencode "saslMechanism=DEFAULT" \
    --data-urlencode "jaasConfig=" \
    "http://$MY_IP:$MY_PORT/clusters"
}


measure() {
  local metrics; metrics=$(echo mntr | nc -u -q3 -w3 127.0.0.1 8125)
  [ -n "$metrics" ] || return 1

  cat << METRICS_EOF
  {
    "heap_usage": $(parseMetrics "$metrics" ".jvm.memory.heap.usage" 100),
    "MessagesInPerSec_1MinuteRate": $(parseMetrics "$metrics" ".kafka.server.BrokerTopicMetrics.MessagesInPerSec.1MinuteRate"),
    "BytesInPerSec_1MinuteRate": $(parseMetrics "$metrics" ".kafka.server.BrokerTopicMetrics.BytesInPerSec.1MinuteRate"),
    "BytesOutPerSec_1MinuteRate": $(parseMetrics "$metrics" ".kafka.server.BrokerTopicMetrics.BytesOutPerSec.1MinuteRate"),
    "Replica_MaxLag": $(parseMetrics "$metrics" "kafka.server.ReplicaFetcherManager.MaxLag.Replica"),
    "KafkaController_ActiveControllerCount": $(parseMetrics "$metrics" ".kafka.controller.KafkaController.ActiveControllerCount"),
    "KafkaController_OfflinePartitionsCount": $(parseMetrics "$metrics" ".kafka.controller.KafkaController.OfflinePartitionsCount")
  }
METRICS_EOF
}

parseMetrics() {
  local metrics="$1" key="$2" factor
  [ -z "$3" ] || factor="*$3"
  echo "$metrics" | xargs -n1 | awk -F: 'BEGIN{value=""} $1=="'$key'"{value=$2} END{print (value=="" ? 0 : value'$factor')}'
}

$1 ${@:2}
