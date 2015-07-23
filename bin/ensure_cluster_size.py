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
# Makes a pass over the specified cluster and removes any nodes that are
# in a TERMINATED, STOPPING, or unknown state.
# Makes a pass over the specified cluster and adds nodes such that the
# number of nodes is consistent with the value in the cluster configuration.

import elasticluster
import cluster_util

import os
import sys

# Check usage
if len(sys.argv) < 2 or len(sys.argv) > 3:
  print "Usage: {} [cluster] <node_type>".format(sys.argv[0])
  sys.exit(1)

cluster_name=sys.argv[1]
node_type=sys.argv[2] if len(sys.argv) > 2 else None

# Testing modes
#
# DRYRUN=1: do not remove any nodes, just display a log of the operations
#           that would occur
# REMOVENODES=<node list>: remove the requested node(s)

dryrun=os.environ['DRYRUN'] if 'DRYRUN' in os.environ else None
removenodes=os.environ['REMOVENODES'].split(',') \
  if 'REMOVENODES' in os.environ else []

# BEGIN MAIN

known_hosts_file = '%s/%s' % (
  os.environ['HOME'], '.elasticluster/storage/%s.known_hosts' % cluster_name)

# Create the elasticluster configuration endpoint
configurator = elasticluster.get_configurator()

# Lookup the cluster
cluster = configurator.load_cluster(cluster_name)
cluster.update()

# Build a list of nodes to remove
if removenodes:
  print "Testing with node list: %s" % ",".join(removenodes)
  to_remove = cluster_util.get_nodes_by_name(cluster, removenodes)
else:
  print "************************************"
  print "Determining status of existing nodes"
  print "************************************"
  to_remove = \
    cluster_util.get_stopped_or_terminated_nodes(cluster, node_type)
print

if to_remove:
  print "***************"
  print "Removing nodes:"
  print "***************"
else:
  print "******************"
  print "No nodes to remove"
  print "******************"
print
  
for node in to_remove:
  print "Removing node %s (%s)" % (node.name, node.preferred_ip)
  if not dryrun:
    cluster_util.run_elasticluster(
      ['remove-node', '--yes', cluster_name, node.name])

    cluster_util.remove_known_hosts_entry(node, known_hosts_file)

print "*********************"
print "Checking cluster size"
print "*********************"

# Re-load the cluster
cluster = configurator.load_cluster(cluster_name)
cluster.update()

target_nodes = cluster_util.get_desired_cluster_nodes(cluster_name)

for kind in cluster.nodes:
  print "Node type (%s): Has: %d, Should have: %d" % (
    kind, len(cluster.nodes[kind]), target_nodes[kind])

  diff = target_nodes[kind] - len(cluster.nodes[kind])
  if diff > 0:
    print "Adding new nodes of type %s" % kind
    print
    if not dryrun:
      cluster_util.run_elasticluster(
        ['resize', cluster_name, '-a' '%d:%s' % (diff, kind)])

