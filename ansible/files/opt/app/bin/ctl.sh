#!/usr/bin/env bash

set -eo pipefail

. /opt/app/bin/.env

svc() {
  systemctl $@ $MY_ROLE
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

init() {
  if [ "$MY_ROLE" = "kafka" ]; then
    mkdir -p /data/kafka/{kafka-logs,logs}
    chown -R kafka.kafka /data/kafka
  fi
  svc unmask -q
  svc enable -q
}

checkPorts() {
  local port; for port in $MY_PORTS; do nc -z -w3 $MY_IP $port; done
}

check() {
  svc is-active -q
  checkPorts
}

start() {
  svc start
  retry 60 1 0 check
}

stop() {
  svc stop
}

restart() {
  stop && start
}

update() {
  if svc is-enabled -q; then restart; fi
}

$1 ${@:2}
