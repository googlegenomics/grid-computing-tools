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

# Sometimes when adding or removing nodes, elasticluster configuration
# of the cluster fails. When it does, it emits a message indicating
# "please re-run elasticluster setup" (thought it exits with a success (0)
# status code).
#
# We capture each add/remove node operation to a logfile and then just grep
# for the error message. If we find it, then we re-run elasticluster setup.
readonly TMPFILE=/tmp/$(basename $0)-${CLUSTER}.log

# remove_terminated_nodes
#
# Remove from the cluster any nodes marked as TERMINATED.
# Capture output to a logfile to inspect for errors.
function remove_terminated_nodes() {
  date
  python -u ${SCRIPT_DIR}/remove_terminated_nodes.py ${CLUSTER} 2>&1 \
    | tee ${TMPFILE}
}
readonly -f remove_terminated_nodes

# ensure_cluster_size
#
# Add nodes to the cluster if the number configured is not at least
# as many as specified in the cluster configuration.
# Capture output to a logfile to inspect for errors.
function ensure_cluster_size() {
  date
  python -u ${SCRIPT_DIR}/ensure_cluster_size.py ${CLUSTER} 2>&1 \
    | tee ${TMPFILE}
}
readonly -f ensure_cluster_size

# check_elasticluster_error
#
# Check the logfile for instructions from Elasticluster to re-run
# "elasticluster setup".
function check_elasticluster_error() {
  grep --quiet --ignore-case \
    "please re-run elasticluster setup" ${TMPFILE}
}
readonly check_elasticluster_error

# check_elasticluster_ready
#
# Check the logfile for instructions from Elasticluster that the
# cluster is ready. When remove_terminated_nodes and ensure_cluster_size
# run, they may not end up running elasticluster setup, so the absence
# of this message does not necessarily indicate a failure. It may be
# that no cluster changes occurred at all.
function check_elasticluster_ready() {
  grep --quiet \
    "Your cluster is ready!" ${TMPFILE}
}
readonly check_elasticluster_ready

# check_cleanup_cluster
#
# We don't currently have a great way to get a coded error response from
# Elasticluster operations. This can make it hard to decide here whether
# to actually re-run "elasticluster setup" as recommended.
#
# One case where you would *not* want to continue to re-run "setup"
# is if a node were terminated (and not yet removed from the cluster).
# Thus each time we have an operational failure, we try re-running
# "setup" once, and if problems persist, then try removing TERMINATED
# nodes before re-running setup.
function check_cleanup_cluster() {
  local error_detected=0

  while [[ ${error_detected} -eq 1 ]] || check_elasticluster_error; do

    echo "*****************************************************************"
    echo "Setup errors detected. Running: elasticluster setup -v ${CLUSTER}"
    echo "*****************************************************************"

    date
    elasticluster setup -v ${CLUSTER} 2>&1 | tee ${TMPFILE}

    echo "***************************************************"
    echo "Finished running: elasticluster setup -v ${CLUSTER}"
    echo "***************************************************"

    if ! check_elasticluster_error; then
      break
    fi

    error_detected=1

    remove_terminated_nodes

    if check_elasticluster_ready; then
      break
    fi
  done
}
readonly -f check_cleanup_cluster

# MAIN loop

while :; do
  # Remove any terminated nodes
  remove_terminated_nodes
  check_cleanup_cluster

  # Remove server keys from the known_host file for removed nodes 
  if ! python -u ${SCRIPT_DIR}/sanitize_known_hosts.py ${CLUSTER}; then
    echo "Continuing..."
  fi

  # Add new nodes so that the cluster is at full strength
  ensure_cluster_size
  check_cleanup_cluster

  echo "Sleeping for ${SLEEP_MINUTES} minutes"
  sleep ${SLEEP_MINUTES}m
done
