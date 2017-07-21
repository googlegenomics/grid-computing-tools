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

# cluster_util.py
#
# Utility routines for managing an Elasticluster cluster.

import elasticluster
import elasticluster.conf
from elasticluster.__main__ import ElastiCluster

import json
import subprocess

def remove_known_hosts_entry(node, known_hosts_file):
  """For a give node, remove any host key entries in the known_hosts file"""

  if not node.preferred_ip:
    return False

  ip=node.preferred_ip

  # Assume concurrency on the known_hosts file is not an issue
  # Read all the lines and then rewrite the file omitting any
  # that match the "preferred IP" (the public IP)
  
  lines = open(known_hosts_file, "r").readlines()

  with open(known_hosts_file, "w") as f:
    for line in lines:
      if not line.startswith(ip + " "):
        f.write(line)

  return True

def get_zone_for_cluster(cluster_name):
  """Returns the GCE zone associated with the cluster.

  There appears to be an elasticluster bug where the zone is not saved
  with the cluster. So we will pull it from the existing configuration
  (we assume the cluster configuration has not been changed)."""

  creator = elasticluster.conf.make_creator(ElastiCluster.default_configuration_file)

  # FIXME: should not assume the template name is the same as the cluster_name
  conf = creator.cluster_conf[cluster_name]
  return conf['cloud']['zone']


def get_nodes_by_name(cluster, node_name_list):
  """Returns a list of node objects for the input list of node names"""
  node_list = []

  for node in cluster.get_all_nodes():
    if node.name in node_name_list:
      print "Adding node %s (%s)" % (node.name, node.instance_id)
      node_list.append(node)
  
  return node_list


def get_node_status(project_id, node, zone):
  """Returns the GCE instance status for the specified zone"""
  if not node.instance_id:
    print "node %s has no instance_id"
    return "UNKNOWN"

  try:
    print "Get status for %s (%s)" % (node.name, node.instance_id)
    out = subprocess.check_output(["gcloud",
                                   "--project", project_id,
                                   "compute", "instances",
                                   "describe", node.instance_id,
                                   "--zone", zone,
                                   "--format", "json"],
                                   stderr=subprocess.STDOUT)
    details = json.loads(out)
    print "Node %s: %s" % (node.name, details['status'])
    return details['status']
  except subprocess.CalledProcessError, e:
    print e.output
    return 'UNKNOWN'


def get_nodes_with_status(cluster, node_type, status_list):
  """Returns a list of nodes with the specified instance status"""
  node_list = []

  zone = get_zone_for_cluster(cluster.name)
  project_id = cluster.cloud_provider._project_id

  for node in cluster.get_all_nodes():
    if not node_type or node['kind'] == node_type:
      status = get_node_status(project_id, node, zone)

      if status in status_list:
        node_list.append(node)

  return node_list


def get_stopping_or_terminated_nodes(cluster, node_type):
  """Returns a list of nodes with STOPPING, TERMINATED, or UNKNOWN status"""

  # Adding nodes with "UNKNOWN" may be an incorrect assumption;
  # a node could be starting,
  # but the only way to be sane is to assume no one else is updating
  # the cluster.
  return get_nodes_with_status(cluster, node_type, 
                               ['STOPPING', 'TERMINATED', 'UNKNOWN'])


def get_desired_cluster_nodes(cluster_name):
  """Returns a dictionary object with a mapping of the node types
  to their desired count (based on cluster configuration)"""

  nodes = {}

  creator = elasticluster.conf.make_creator(ElastiCluster.default_configuration_file)

  # FIXME: should not assume the template name is the same as the cluster_name
  conf = creator.cluster_conf[cluster_name]
  for key in conf['cluster']:
    if key.endswith('_nodes'):
      kind = key[:-len('_nodes')]
      nodes[kind] = int(conf['cluster'][key])

  return nodes


def run_elasticluster(argv):
  """Execute the specified elasticluster command"""

  # Currently highly verbose: make the "-v" level optional
  return subprocess.call(["elasticluster", "-v", "-v", "-v"] + argv)

