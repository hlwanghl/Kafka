#!/usr/bin/env bash

set -eo pipefail

. /opt/app/bin/.env

EC_HTTP_ERROR=20

command=$1
log() {
  logger -t appctl --id=$$ [cmd=$command] $@
}

svc() {
  systemctl $@ $MY_ROLE $EXTRA_SVCS
}

startZabbix() {
  if [ "$zabbix_enable" = "true" ]; then 
    systemctl stop  zabbix-agent
    systemctl start zabbix-agent
  else
    systemctl stop  zabbix-agent
    log "zabbix-agent start failed..."  
  fi
}
retry() {
  local tried=0
  local maxAttempts=$1
  local interval=$2
  local stopCode=$3
  local cmd="${@:4}"
  local retCode=$EC_RETRY_FAILED
  while [ $tried -lt $maxAttempts ]; do
    $cmd && return 0 || {
      retCode=$?
      if [ "$retCode" = "$stopCode" ]; then
        log "'$cmd' returned with stop code $stopCode. Stopping ..." && return $retCode
      fi
    }
    sleep $interval
    tried=$((tried+1))
  done

  log "'$cmd' still returned errors after $tried attempts. Stopping ..." && return $retCode
}

startzabbix() {

  if [ "$ZABBIX_AGENT_ENABLE" = "true" ]; then 
    service zabbix-agent start 
  else 
    log "zabbix-agent start failed..."  
  fi
}

init() {
  if [ "$MY_ROLE" = "kafka-manager" ]; then echo 'root:kafka' | chpasswd; echo 'ubuntu:kafka' | chpasswd; fi
  mkdir -p /data/zabbix
  chown -R zabbix.zabbix /data/zabbix
  mkdir -p /data/zabbix/zabbix_agentd.log
  chown -R zabbix.zabbix /data/zabbix/zabbix_agentd.log
  mkdir -p /data/$MY_ROLE/{dump,logs}
  chown -R kafka.kafka /data/$MY_ROLE
  local htmlFile=/data/$MY_ROLE/index.html
  [ -e "$htmlFile" ] || ln -s /opt/app/conf/caddy/index.html $htmlFile
  svc unmask -q
  systemctl unmask zabbix-agent
}

isInitialized() {
  [ "$(systemctl is-enabled ${MY_ROLE})" = "disabled" ]
}

checkPorts() {
  local ports="$MY_PORT $EXTRA_PORTS"
  local port; for port in $ports; do nc -z -w3 $opts $MY_IP $port; done
}

checkHttp() {
  local host=${1:-$MY_IP} port=${2:-80}
  local code="$(curl -s -o /dev/null -w "%{http_code}" $host:$port)"
  [[ "$code" =~ ^(200|302|401|403|404)$ ]] || {
    log "HTTP status check failed to $host:$port: code=$code."
    return $EC_HTTP_ERROR
  }
}

check() {
  if [ "${ZABBIX_AGENT_ENABLE}" = "true" ] && [ 'systemctl is-active zabbix-agent -q' ]; then
    svc is-active -q
    checkPorts
  fi
}

start() {
  isInitialized || init
  svc start
  retry 60 1 0 check
  if [ "$MY_ROLE" = "kafka-manager" ]; then
    retry 60 1 0 checkHttp $MY_IP $MY_PORT
    local httpCode="$(addCluster)"
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

stop() {
  systemctl stop zabbix-agent 
  svc stop
}

restart() {
  stop && start
}

update() {
  if [ "$(systemctl is-enabled $MY_ROLE)" = "disabled" ]; then restart; fi
}

revive() {
  check || restart
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
