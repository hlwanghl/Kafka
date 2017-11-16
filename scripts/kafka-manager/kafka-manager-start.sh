#!/bin/bash
rm -rf /opt/kafka-manager/RUNNING_PID
nohup /opt/kafka-manager/bin/kafka-manager -Dconfig.file=/opt/kafka-manager/conf/application.conf >/data/kafka-manager.log 2>&1 &
