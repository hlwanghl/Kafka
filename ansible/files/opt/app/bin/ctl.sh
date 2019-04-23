#!/usr/bin/env bash

set -e

. /opt/app/bin/.env

svc() {
  systemctl $@ $MY_ROLE
}

start() {
  svc start
}

stop() {
  svc stop
}