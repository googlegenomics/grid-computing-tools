#! /usr/bin/env python

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

# list_all_nodes.py
#
# Utility script that returns a list of elasticluster node names
# for a cluster.

import elasticluster

import sys

# Check usage
if len(sys.argv) != 2:
  print "Usage: {} [cluster]".format(sys.argv[0])
  sys.exit(1)

cluster_name=sys.argv[1]

# Create the elasticluster configuration endpoint
configurator = elasticluster.get_configurator()

# Lookup the cluster
cluster = configurator.load_cluster(cluster_name)

# Emit the node names
for node in cluster.get_all_nodes():
  print node['name']

