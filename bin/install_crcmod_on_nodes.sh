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

# install_crcmod.sh
#
# Utility script that connects to each node of a cluster
# and installs the python crcmod module required by gsutil
# to download multi-component objects.
# The "node type" can optionally be specified such that, for example,
# the operation can be restricted to all "compute" nodes in the cluster.

set -o errexit
set -o nounset

if [[ $# -lt 1 ]]; then
  >&2 echo "Usage: ${0} [cluster]"
  exit 1
fi

readonly CLUSTER=${1}

# Set of commands for Debian and Ubuntu as per "gsutil help crcmod"
readonly COMMANDS='
sudo apt-get update --yes
sudo apt-get install --yes gcc python-dev python-setuptools
sudo easy_install -U pip
sudo pip uninstall --yes crcmod
sudo pip install -U crcmod
'

# Use the list_all_nodes.py python script to get the list of instances
readonly SCRIPT_DIR=$(dirname ${0})
readonly NODES=$(python ${SCRIPT_DIR}/list_all_nodes.py ${CLUSTER})

# Sequentially connect to the nodes and run the commands
for NODE in ${NODES}; do
  elasticluster ssh ${CLUSTER} "${COMMANDS}" -n ${NODE}
done

