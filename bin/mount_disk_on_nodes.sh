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

# mount_my_disk.sh
#
# Utility script that connects to each node of a cluster
# and mounts the specified disk read-only.
# The "node type" can optionally be specified such that, for example,
# the operation can be restricted to all "compute" nodes in the cluster.

set -o errexit
set -o nounset

if [[ $# -lt 3 ]]; then
  >&2 echo "Usage: ${0} [cluster] [disk_name] [mount_point] <node_type>"
  exit 1
fi

readonly CLUSTER=${1}
readonly DISK_NAME=${2}
readonly MOUNT_POINT=${3}
readonly NODE_TYPE=${4:-}

# Set of commands for Debian and Ubuntu as per "gsutil help crcmod"
readonly COMMANDS='
if ! mount -l | grep "'${MOUNT_POINT}'"; then
  sudo mkdir -p "'${MOUNT_POINT}'"
  sudo chmod 777 "'${MOUNT_POINT}'"
  sudo mount -o ro /dev/disk/by-id/google-'"${DISK_NAME}"' '"${MOUNT_POINT}"'
fi
'

# Use the list_all_nodes.py python script to get the list of instances
readonly SCRIPT_DIR=$(dirname ${0})
readonly NODES=$(
  python ${SCRIPT_DIR}/list_all_nodes.py ${CLUSTER} ${NODE_TYPE})

# Sequentially connect to the nodes and run the commands
for NODE in ${NODES}; do
  echo "Mount ${DISK_NAME} on ${NODE}:${MOUNT_POINT}"
  elasticluster ssh ${CLUSTER} "${COMMANDS}" -n ${NODE}
done

