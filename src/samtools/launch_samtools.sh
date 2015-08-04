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

# launch_samtools.sh
#
# Launches a Grid Engine job to run a samtools command over files
# in Google Cloud Storage. Overall flow of operation:
#   * Create Grid Engine "array" job
#   * Each task will
#     * Download one or more files from GCS
#     * Process the file(s)
#     * Upload the file(s) to GCS
#
# The launch script need source and destination information,
# along with an optional destination for logging.
#
# The list of files to act on is assumed to be provided in a pre-generated
# file. This file must contain one GCS path per line.
# The paths may be individual files or a GCS pattern, such as:
#
#   gs://my_bucket/my_path/dir1/by_chrom.*.bam
#   gs://my_bucket/my_path/dir2/sample.bam
#
# Each line gets processed as an individual task. If you want files to
# be processed as separate tasks on separate nodes, then list the files
# explicitly in the list file.
#
# All scripts here respect the DRYRUN environment variable.
# If set to 1, then the operations that *would* be performed will be
# emitted to stdout. This is useful for verifying input and output paths.
#
# Example DRYRUN usage:
#   DRYRUN=1 ./src/samtools/launch_samtools.sh samples/samtools/samtools_index_config.sh
#
# Example real usage:
#   ./src/samtools/launch_samtools.sh samples/samtools/samtools_index_config.sh
#
# The launch script also accepts the environment variables LAUNCH_MIN and
# LAUNCH_MAX, which can be used to specify the minimum and maximum record
# to process. This is useful for small scale testing.
#
# Example DRYRUN processing only the first record:
#   DRYRUN=1 LAUNCH_MIN=1 LAUNCH_MAX=1 ./src/samtools/launch_samtools.sh samples/samtools/samtools_index_config.sh
#
# Example real usage processing only the first 5 records:
#   LAUNCH_MIN=1 LAUNCH_MAX=5 ./src/samtools/launch_samtools.sh samples/samtools/samtools_index_config.sh
#

# The first parameter is a path to a "job configuration" shell script.
# This script must export paths:
#
#  export INPUT_LIST_FILE=<path to local file listing GCS input paths>
#  export OUTPUT_PATH=<GCS path to which to upload output>
#  export OUTPUT_LOG_PATH=<GCS path to which to upload logs>
#  
# This script must export information about what operation to perform:
#
#  export SAMTOOLS_OPERATION="index"   # Only index currently supported

set -o errexit
set -o nounset

if [[ $# -lt 1 ]]; then
  >&2 echo "Usage: ${0} [job_config_file]"
  exit 1
fi

# Task-specific parameters which can be overridden in the job
# config file.
export TASK_SCRATCH_DIR=/scratch

readonly CONFIG_FILE=${1}

source ${CONFIG_FILE}

#
# Input validation
#

readonly REQUIRED_VARS='
INPUT_LIST_FILE
OUTPUT_PATH
OUTPUT_LOG_PATH
SAMTOOLS_OPERATION
'

for VAR in ${REQUIRED_VARS}; do
  if [[ -z "${!VAR:-}" ]]; then
    >&2 echo "Error: ${VAR} must be set"
    exit 1
  fi
done

if [[ ! -e ${INPUT_LIST_FILE} ]]; then
  >&2 echo "Error: ${INPUT_LIST_FILE} not found"
  exit 1
fi

# If LAUNCH_MIN or LAUNCH_MAX are set in the environment, use them.
# Otherwise, launch tasks for all lines in the INPUT_LIST_FILE.
readonly TASK_START=${LAUNCH_MIN:-1}
readonly TASK_END=${LAUNCH_MAX:-$(cat ${INPUT_LIST_FILE} | wc -l)}

#
# Submit the job
#

# Parameters
#  -t: Task range
#  -S: Force the task shell to be bash
#  -V: Pass the current environment through to each task
#  -N: Job name
readonly SAMTOOLS_SRC_ROOT=$(readlink -f $(dirname ${0}))

export SRC_ROOT=$(dirname ${SAMTOOLS_SRC_ROOT})

qsub \
  -t ${TASK_START}-${TASK_END} \
  -S /bin/bash \
  -V \
  -N samtools \
  -r y \
  ${SAMTOOLS_SRC_ROOT}/task_samtools.sh

