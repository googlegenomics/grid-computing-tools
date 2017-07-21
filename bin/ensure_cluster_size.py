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

# ensure_cluster_size.py
#
# Makes a pass over the specified cluster and adds nodes such that the
# number of nodes is at least as high (hopefully equal to) the value in
# the cluster configuration.

import elasticluster
import elasticluster.conf
from elasticluster.__main__ import ElastiCluster

import cluster_util

import os
import sys

# Check usage
if len(sys.argv) != 2:
  print "Usage: {} [cluster]".format(sys.argv[0])
  sys.exit(1)

cluster_name=sys.argv[1]

# Testing modes
#
# DRYRUN=1: do not add any nodes, just display a log of the operations
#           that would occur

dryrun=os.environ['DRYRUN'] if 'DRYRUN' in os.environ else None

# BEGIN MAIN

# Create the elasticluster configuration endpoint
creator = elasticluster.conf.make_creator(ElastiCluster.default_configuration_file)

# Lookup the cluster
cluster = creator.load_cluster(cluster_name)
cluster.update()

print "*********************"
print "Checking cluster size"
print "*********************"

target_nodes = cluster_util.get_desired_cluster_nodes(cluster_name)

for kind in target_nodes:
  has_count = len(cluster.nodes[kind]) if kind in cluster.nodes else 0
  print "Node type (%s): Has: %d, Should have: %d" % (
    kind, has_count, target_nodes[kind])

  diff = target_nodes[kind] - has_count
  if diff > 0:
    print "Adding new nodes of type %s" % kind
    print
    if not dryrun:
      cluster_util.run_elasticluster(
        ['resize', cluster_name,
           '-a' '%d:%s' % (diff, kind),
           '-t', cluster_name])
  elif diff < 0:
    print "WARNING: There are more nodes of type %s than configured" % kind
