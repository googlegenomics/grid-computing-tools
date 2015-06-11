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

# do_compress.sh
#
# Copies one or more files from GCS to disk,
# compresses or decompresses the file(s),
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

# Download the file(s) to (de)compress
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
  bigtools_log::emit "Processing file ${FILE}"

  case "${COMPRESS_OPERATION}" in
    compress)
      # Add the extension to the output file
      INFILE=${WS_IN_DIR}/${FILE}
      OUTFILE=${WS_OUT_DIR}/${FILE}${COMPRESS_EXTENSION}

      CMD="${COMPRESS_TYPE} --stdout ${INFILE} > ${OUTFILE}"
      ;;
    decompress)
      # Trim the extension from the output file
      INFILE=${WS_IN_DIR}/${FILE}
      OUTFILE=${WS_OUT_DIR}/${FILE%${COMPRESS_EXTENSION}}

      CMD="${COMPRESS_TYPE} --decompress --stdout ${INFILE} > ${OUTFILE}"
      ;;
    *)
      bigtools_log::emit "Unknown compression operation: ${COMPRESS_OPERATION}"
      exit 1
      ;;
  esac

  bigtools_log::emit "Command: ${CMD}"

  if [[ ${DRYRUN:-} -eq 1 ]]; then
    continue
  fi

  eval ${CMD}
done
END=$(date +%s)

bigtools_log::emit "Update: ${#FILE_LIST[@]} files in $((END-START)) seconds"

# Upload the output file(s)
if [[ ${DRYRUN:-} -eq 1 ]]; then
  exit 0
fi
gcs_util::upload "${WS_OUT_DIR}/*" "${OUTPUT_PATH}/"

