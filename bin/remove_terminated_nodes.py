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

# remove_terminated_nodes.py
#
# Makes a pass over the specified cluster and removes any nodes that are
# in a TERMINATED, STOPPING, or unknown state.

import elasticluster
import elasticluster.conf
from elasticluster.__main__ import ElastiCluster

import cluster_util

import errno
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
creator = elasticluster.conf.make_creator(ElastiCluster.default_configuration_file)

# Lookup the cluster
cluster = creator.load_cluster(cluster_name)
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
    cluster_util.get_stopping_or_terminated_nodes(cluster, node_type)
print

if not to_remove:
  print "******************"
  print "No nodes to remove"
  print "******************"
  print

  sys.exit(0)

print "***************"
print "Removing nodes:"
print "***************"
print

for node in to_remove:
  print "Removing node %s (%s)" % (node.name, node.preferred_ip)
  if not dryrun:
    cluster_util.run_elasticluster(
      ['remove-node', '--no-setup', '--yes', cluster_name, node.name])

    if not cluster_util.remove_known_hosts_entry(node, known_hosts_file):
      print "No preferred ip for node; removing file %s" % known_hosts_file
      try:
        os.remove(known_hosts_file)
      except OSError as e:
        if e.errno != errno.ENOENT:
          raise

cluster_util.run_elasticluster(['setup', cluster_name])
