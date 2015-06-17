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

# attach_my_disk.sh
#
# Utility script that attaches a disk read-only to each node of a cluster.
# The "node type" can optionally be specified such that, for example,
# the operation can be restricted to all "compute" nodes in the cluster.

set -o errexit
set -o nounset

if [[ $# -lt 3 ]]; then
  >&2 echo "Usage: ${0} [cluster] [disk_name] [zone] <node_type>"
  exit 1
fi

readonly CLUSTER=${1}
readonly DISK_NAME=${2}
readonly ZONE=${3}
readonly NODE_TYPE=${4:-}

# Use the list_all_instances.py python script to get the list of instances
readonly SCRIPT_DIR=$(dirname ${0})
readonly INSTANCES=$(
  python ${SCRIPT_DIR}/list_all_instances.py ${CLUSTER} ${NODE_TYPE})

# Sequentially connect to the nodes and run the command
for INSTANCE_NAME in ${INSTANCES}; do
  echo "Attaching disk ${DISK_NAME} to instance ${INSTANCE_NAME}"
  gcloud compute instances attach-disk ${INSTANCE_NAME} \
    --disk=${DISK_NAME} --device-name=${DISK_NAME} --zone=${ZONE} \
    --mode ro
done

