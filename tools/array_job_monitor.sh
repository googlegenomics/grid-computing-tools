#!/bin/bash

# Copyright 2015 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# array_job_monitor.sh
#
# This script is intended to run on the master node of gridengine cluster.
# It will monitor an array job (specified by job id on the command-line)
# and to detect when a task has stopped running.
#
# The specific problem this addresses is when a worker node of the cluster
# has been removed (perhaps it was a preemptible VM that was TERMINATED).
# gridengine will continue to report the task as in a "r"unning state.
#
# The detection method is fairly crude and timeouts should be tuned
# according to your particular job. When this script runs, it examines
# all currently listed as running tasks for the job. It then checks to
# see if the output/stderr file for the task has been updated within the
# timeout interval you specify. If not, the task is considered dead and
# a restart is requested.

set -o errexit
set -o nounset

readonly JOB_ID=${1}
readonly TIMEOUT_MINUTES=${2}

readonly JOB_NAME=$(
  qstat -j ${JOB_ID} | sed --quiet -e 's#job_name: *\(.*\)#\1#p')

readonly TIMEOUT_INTERVAL=$((TIMEOUT_MINUTES * 60))

echo "Begin: monitoring ${JOB_NAME}.${JOB_ID} every ${TIMEOUT_MINUTES} minutes"

while :; do
   # "qstat -j" will return a dump of data, including lines for each task:
   #   usage  <task_id>:   cpu=<blah>, mem=<blah>
   TASK_LIST=$(qstat -j ${JOB_ID} | \
               sed --quiet -e 's#^usage *\([0-9]\+\):.*#\1#p')

   NOW=$(date +%s)
   for TASK_ID in ${TASK_LIST}; do
     echo "Checking ${JOB_ID}.${TASK_ID}"

     # "stat --format=%Y" returns the last modified time of the file(s)
     LAST_MOD_TIMES=$(stat --format=%Y ${JOB_NAME}.[oe]${JOB_ID}.${TASK_ID})
     for LAST_MOD_TIME in ${LAST_MOD_TIMES}; do
       ALIVE=0
       if [[ $((NOW - LAST_MOD_TIME)) -lt ${TIMEOUT_INTERVAL} ]]; then
         ALIVE=1
         break
       fi
    done

    if [[ ${ALIVE} -eq 0 ]]; then
       echo "${JOB_ID}.${TASK_ID} appears to be dead; requesting restart"
       qmod -r ${JOB_ID}.${TASK_ID}
    fi
  done

  sleep ${TIMEOUT_MINUTES}m
done
