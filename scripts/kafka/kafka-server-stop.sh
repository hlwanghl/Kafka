#!/bin/sh
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
PIDS=$(ps -ef  | grep  kafka |grep -v grep |grep java | awk '{print $2}')
if [ -z "$PIDS" ]; then
  echo "No kafka server to stop"
else
  kill -s TERM $PIDS
# Check if kafka server  is terminated
  for i in $(seq 0 5); do
     if ! ps -ef | grep Kafka | grep java | grep -v grep > /dev/null; then
         echo "kafka server  is successfully terminated" 1>&2
         exit 0
     fi
     sleep 1
  done
# do kill kafka server
 kill -9 $PIDS
  if [ $? -eq 0 ]; then
      echo "kafka server is successfully killed" 1>&2
      exit 0
  else
      echo "Failed to kill kafka server"  1>&2
      exit 1
  fi

fi

