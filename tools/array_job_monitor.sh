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
# and to detect when a task has stopped running due to a node failure.
#
# The specific problem this addresses is when a worker node of the cluster
# has been removed (perhaps it was a preemptible VM that was TERMINATED).
# gridengine will continue to report the task as in a "r"unning state.
#
# The function of this script *should* be taken care of by grid engine
# itself, namely the configuration values:
#  * reschedule_unknown
#  * max_unheard
# However I was never able to get them to work *reliably* and frequently
# ended up with tasks stuck in a "r"unning state on machines that had
# been terminated.

set -o errexit
set -o nounset

readonly JOB_ID=${1}
readonly TIMEOUT_MINUTES=${2}
readonly QUEUE_NAME=${3:-all.q}

readonly JOB_NAME=$(
  qstat -j ${JOB_ID} | sed --quiet -e 's#job_name: *\(.*\)#\1#p')

readonly TIMEOUT_INTERVAL=$((TIMEOUT_MINUTES * 60))

echo "Begin: monitoring ${JOB_NAME}.${JOB_ID} every ${TIMEOUT_MINUTES} minutes"

while :; do
   # qstat will return a list of all running tasks where the interesting
   # lines look like:
   #   3 0.50000 samtools   mbookman     r    08/06/2015 18:22:19 
   #   all.q@compute002                   1 376

   # Grab all of the lines for this job
   # For each line - check the status of the associated node

   TASK_LIST=$(qstat | \
               awk -v job=${JOB_ID} -v queue=${QUEUE_NAME} \
               '$1 == job && $8 ~ queue"@" {
                  printf "%s,%s,%s,%s\n", $10, $8, $6, $7 }')

   for TASK in ${TASK_LIST}; do
     TASK_ID=$(echo "${TASK}" | cut -d , -f 1)
     QUEUE=$(echo "${TASK}" | cut -d , -f 2)
     TASK_START_DATE="$(echo "${TASK}" | cut -d , -f 3)"
     TASK_START_TIME="$(echo "${TASK}" | cut -d , -f 4)"
     TASK_START="${TASK_START_DATE} ${TASK_START_TIME}"

     # Trim the "all.q@" from the front of the queue
     NODE=${QUEUE##${QUEUE_NAME}@}

     # To get the uptime of the system, grab the first value from /proc/uptime
     # If we fail to connect to the target host, the output will be empty.
     UPTIME_SEC=$(ssh -o ConnectTimeout=20 ${NODE} \
                    cat /proc/uptime | awk '{ print $1 }')

     RESTART_TASK=0
     if [[ -z ${UPTIME_SEC} ]]; then
       echo "Node ${NODE} unreachable"
       RESTART_TASK=1
     else
       # Convert the uptime (float) to an integer
       UPTIME_SEC=$(printf '%.0f' ${UPTIME_SEC})

       # Convert the start time string to seconds since the epoch
       TASK_START_SEC=$(date -d "${TASK_START}" '+%s')

       # Get the current time as seconds since the epoch
       NOW=$(date '+%s')

       if [[ ${TASK_START_SEC} < $((NOW - UPTIME_SEC)) ]]; then
         echo "Node ${NODE} appears to have been restarted"
         echo "  Node uptime: ${UPTIME_SEC} sec"
         echo "  Task start: ${TASK_START_SEC} sec, (${TASK_START})"
         echo "  Now: ${NOW}, $(date '+%D %T')"

         RESTART_TASK=1
       fi
     fi

     if [[ ${RESTART_TASK} -eq 1 ]]; then
       echo "${JOB_ID}.${TASK_ID} appears to be dead; requesting restart"
       qmod -r ${JOB_ID}.${TASK_ID}
     fi
  done

  echo "Sleeping ${TIMEOUT_MINUTES} minute(s)"
  sleep ${TIMEOUT_MINUTES}m
done
