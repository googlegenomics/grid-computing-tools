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

# do_samtools.sh
#
# Copies one or more files from GCS to disk,
# runs a samtools command
# and pushes the results into GCS.

set -o errexit
set -o nounset

# Required inputs parameters:
readonly WORKSPACE_DIR=${1}
readonly INPUT_PATH=${2}
readonly OUTPUT_PATH=${3}

readonly WS_IN_DIR=${WORKSPACE_DIR}/in
readonly WS_OUT_DIR=${WORKSPACE_DIR}/out

source ${SRC_ROOT}/common/logging.sh
source ${SRC_ROOT}/common/gcs_util.sh

# Make sure our workspace directories are clean and ready
for DIR in ${WS_IN_DIR} ${WS_OUT_DIR}; do
  sudo rm -rf ${DIR}/*
  sudo mkdir -p ${DIR} --mode 777
done
unset DIR

# Download the file(s) to processed
gcs_util::download "${INPUT_PATH}" "${WS_IN_DIR}/"

# Get an array of input files
declare -a FILE_LIST
if [[ ${DRYRUN:-} -eq 1 ]]; then
  # The FILE_LIST will be empty for a DRYRUN; try to fake it
  DRYRUN_LIST=$(gcs_util::get_file_list "${INPUT_PATH}")
  FILE_LIST=($(echo "${DRYRUN_LIST}" | sed -e 's#.*/##'))
else
  FILE_LIST=($(/bin/ls -1 ${WS_IN_DIR}))
fi
readonly FILE_LIST

# Process the input files
START=$(date +%s)
for FILE in "${FILE_LIST[@]}"; do
  logging::emit "Processing file ${FILE}"

  case "${SAMTOOLS_OPERATION}" in
    index)
      # The output file name cannot be changed for "samtools index"
      INFILE=${WS_IN_DIR}/${FILE}
      OUTFILE=${WS_IN_DIR}/${FILE}.bai

      CMD="samtools index ${INFILE}"
      ;;
    *)
      logging::emit "Unknown operation: ${SAMTOOLS_OPERATION}"
      exit 1
      ;;
  esac

  logging::emit "Command: ${CMD}"

  if [[ ${DRYRUN:-} -eq 1 ]]; then
    continue
  fi

  eval ${CMD}
done
END=$(date +%s)

logging::emit "Update: ${#FILE_LIST[@]} files in $((END-START)) seconds"

# Upload the output file(s)
if [[ ${OUTPUT_PATH} == "source" ]]; then
  OUTPUT_PATH=$(dirname ${INPUT_PATH})
fi
gcs_util::upload "${OUTFILE}" "${OUTPUT_PATH}/"

