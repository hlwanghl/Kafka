#!/bin/bash
/opt/kafka-manager/bin/kafka-manager-stop.sh
sleep 2
nohup /opt/kafka-manager/bin/kafka-manager -Dconfig.file=/opt/kafka-manager/conf/application.conf >/data/kafka-manager.log 2>&1 &
