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

# task_samtools.sh
#
# Wrapper script that sets up the call to the actual worker:
#   do_samtools.sh
#
# This script isolates from do_samtools.sh that Grid Engine is
# managing the operation and do_samtools can be dedicated to its
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
export LOGGING_LOG_FILE=${WORKSPACE_DIR}/${JOB_NAME}.${JOB_ID}.${SGE_TASK_ID}.log
readonly TASK_START_TIME=$(date '+%s')

# For debugging, emit the hostname and inputs
logging::emit "Task host: $(hostname)"
logging::emit "Task start: ${SGE_TASK_ID}"
logging::emit "Input list file: ${INPUT_LIST_FILE}"
logging::emit "Output path: ${OUTPUT_PATH}"
logging::emit "Output log path: ${OUTPUT_LOG_PATH:-}"
logging::emit "Scratch dir: ${TASK_SCRATCH_DIR}"

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

    logging::emit "Task time ${SGE_TASK_ID}: $((end - start)) seconds"
    gcs_util::upload_log "${LOGGING_LOG_FILE}" "${OUTPUT_LOG_PATH}/"
  fi
}
readonly -f finish

# Make sure that the crcmod library is installed
gcs_util::install_crcmod

# Make sure that samtools is installed
if which samtools &> /dev/null; then
  echo "samtools is installed"
else
  sudo apt-get install --yes samtools
fi

# Grab the record to process
readonly INPUT_PATH=$(sed -n "${SGE_TASK_ID}p" ${INPUT_LIST_FILE})
logging::emit "Processing ${INPUT_PATH}"

# Special-case the output path
if [[ ${OUTPUT_PATH} == "source" ]]; then
  OUTPUT_PATH=$(dirname ${INPUT_PATH})
  logging::emit "Output path set to: ${OUTPUT_PATH}"
fi

# Launch the job
if ${SRC_ROOT}/samtools/do_samtools.sh \
      ${WORKSPACE_DIR} \
      ${INPUT_PATH} \
      ${OUTPUT_PATH}; then
  logging::emit "Task end SUCCESS: ${SGE_TASK_ID}"
else
  logging::emit "Task end FAILURE: ${SGE_TASK_ID}"
fi

finish

