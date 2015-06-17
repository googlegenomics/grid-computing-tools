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

# task_compress.sh
#
# Wrapper script that sets up the call to the actual worker:
#   do_compress.sh
#
# This script isolates from do_compress.sh that Grid Engine is
# managing the operation and do_compress can be dedicated to its
# specific task.
#
# When a single command in the array job is sent to a compute node,
# its task number is stored in the variable SGE_TASK_ID,
# so we can use the value of that variable to determine the inputs

set -o errexit
set -o nounset

source ${SRC_ROOT}/common/logging.sh
source ${SRC_ROOT}/common/gcs_util.sh

# Set up an EXIT trap to be sure to clean up
trap exit_clean EXIT

# Set the workspace dir
readonly WORKSPACE_DIR=${TASK_SCRATCH_DIR}/${JOB_NAME}.${JOB_ID}.${SGE_TASK_ID}
sudo mkdir -p ${WORKSPACE_DIR} -m 777

# Set the log file
export BIGTOOLS_LOG_FILE=${WORKSPACE_DIR}/${JOB_NAME}.${JOB_ID}.${SGE_TASK_ID}.log
readonly TASK_START_TIME=$(date '+%s')

# For debugging, emit the hostname and inputs
bigtools_log::emit "Task host: $(hostname)"
bigtools_log::emit "Task start: ${SGE_TASK_ID}"
bigtools_log::emit "Input list file: ${INPUT_LIST_FILE}"
bigtools_log::emit "Output path: ${OUTPUT_PATH}"
bigtools_log::emit "Output log path: ${OUTPUT_LOG_PATH:-}"
bigtools_log::emit "Scratch dir: ${TASK_SCRATCH_DIR}"

# Set up an EXIT trap to be sure to clean up
function exit_clean() {
  # If the WORKSPACE_DIR variable has been set, then be sure to clean up
  if [[ -n ${WORKSPACE_DIR:-} ]]; then
    sudo rm -rf ${WORKSPACE_DIR}
  fi
}
readonly -f exit_clean

function finish() {
  # Upload the log file
  if [[ -n ${OUTPUT_LOG_PATH:-} ]]; then
    local start=${TASK_START_TIME}
    local end=$(date '+%s')

    bigtools_log::emit "Task time ${SGE_TASK_ID}: $((end - start)) seconds"
    gcs_util::upload_log "${BIGTOOLS_LOG_FILE}" "${OUTPUT_LOG_PATH}/"
  fi
}
readonly -f finish

# Make sure that the crcmod library is installed
gcs_util::install_crcmod

# Grab the record to process
readonly INPUT_PATTERN=$(sed -n "${SGE_TASK_ID}p" ${INPUT_LIST_FILE})
bigtools_log::emit "Processing ${INPUT_PATTERN}"

# Launch the job
for ((i = 0; i < ${TASK_MAX_ATTEMPTS}; i++)); do
  # Access to GCS can hang at times; just whack the job and try again
  if timeout ${TASK_TIMEOUT} \
      ${SRC_ROOT}/compress/do_compress.sh \
      ${WORKSPACE_DIR} \
      ${INPUT_PATTERN} \
      ${OUTPUT_PATH}; then
    bigtools_log::emit "Task end SUCCESS: ${SGE_TASK_ID}"
    finish
    exit 0
  fi

  bigtools_log::emit "Retrying task ${SGE_TASK_ID}"
done

# All done
bigtools_log::emit "Task end FAILURE: ${SGE_TASK_ID}"
finish

