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

# cluster_monitor.sh
#
# Runs continuously to ensure that the specified cluster contains
# the number of configured instances. If members of the cluster are
# found to be TERMINATED, they are removed fromt he cluster and
# replacement instances are created
#
# Usage:
#   cluster_monitor.sh <cluster-name> [sleep_minutes]
# Where:
#   cluster-name is the Elasticluster cluster name
#   sleep_minutes is how long to sleep between checks (default 10)

set -o errexit
set -o nounset

if [[ $# -lt 1 ]]; then
  echo "Usage: ${0} [cluster] <sleep_minutes>"
  exit 1
fi

readonly CLUSTER=${1}
readonly SLEEP_MINUTES=${2:-10}

readonly SCRIPT_DIR=$(dirname $0)

while :; do
  python ${SCRIPT_DIR}/ensure_cluster_size.py ${CLUSTER}

  echo "Sleeping for ${SLEEP_MINUTES} minutes"
  sleep ${SLEEP_MINUTES}m
done
