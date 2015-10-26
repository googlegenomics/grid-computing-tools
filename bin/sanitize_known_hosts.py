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

# sanitize_known_hosts.py
#
# Lists all instances of an Elasticluster cluster and rewrites
# the known_hosts file with only those members.

import elasticluster
import paramiko

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

# Get the list of IP addresses
ip_addrs = [node.preferred_ip for node in cluster.get_all_nodes()]
print "Known ip addresses for cluster %s" % cluster_name
print ip_addrs

try:
  keys = paramiko.hostkeys.HostKeys(cluster.known_hosts_file)
except IOError as e:
  print e
  sys.exit(1)

print "Keyfile %s loaded" % cluster.known_hosts_file

new_keys = paramiko.hostkeys.HostKeys()

for ip_addr in ip_addrs:
  node_host_keys = keys.lookup(ip_addr)
  if node_host_keys:
    for key_type in node_host_keys.keys():
      new_keys.add(node_host_keys._hostname, key_type, node_host_keys[key_type])

print "Saving sanitized keyfile %s" % cluster.known_hosts_file
new_keys.save(cluster.known_hosts_file)
