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

# gcs_util::install_crcmod
#
# Installs the compiled crcmod library if it is not installed
# See:
#  https://cloud.google.com/storage/docs/gsutil/addlhelp/CRC32CandInstallingcrcmod
function gcs_util::install_crcmod() {
  local crcmod_installed=$(\
    gsutil version -l | sed -n -e 's/^compiled crcmod: *//p')

  logging::emit "Compiled crcmod installed: ${crcmod_installed}"
  if [[ ${crcmod_installed} != "True" ]]; then
    logging::emit "Installing compiled crcmod"
    sudo apt-get update --yes
    sudo apt-get install --yes gcc python-dev python-setuptools
    sudo easy_install -U pip
    sudo pip uninstall --yes crcmod || true
    sudo pip install -U crcmod
  fi
}
readonly -f gcs_util::install_crcmod

# gcs_util::download
#
# Copies the matching objects at the specified remote path
# to the specified target.
#
# Logs the number of bytes downloaded, the number of seconds,
# and the overall throughput.
#
# Respects the DRYRUN environment variable; if set to 1, then
# logs the operation (with to and from path) and returns.
function gcs_util::download() {
  local remote_path=${1}
  local local_path=${2}

  logging::emit "Will download: ${remote_path} to ${local_path}"
  if [[ ${DRYRUN:-} -eq 1 ]]; then
    return
  fi

  # Track the number of bytes we download.
  # Get the number of bytes already in the destination directory
  # (and assume no one else is writing to the directory).
  local bytes_start=$(du -s --bytes ${local_path} | cut -f 1 -d $'\t')

  # Download the file(s)
  local time_start=$(date +%s)
  gsutil -m cp ${remote_path} ${local_path}
  local time_end=$(date +%s)

  local bytes_end=$(du -s --bytes ${local_path} | cut -f 1 -d $'\t')

  local bytes=$((bytes_end - bytes_start))
  local time=$((time_end - time_start))

  logging::emit "Download: ${bytes} bytes in ${time} seconds"
  logging::emit "Download rate: $(( (bytes/1000/1000) / time )) MB/s"
}
readonly -f gcs_util::download

# gcs_util::upload
#
# Copies the matching objects at the specified local path
# to the specified target.
#
# Logs the number of bytes uploaded, the number of seconds,
# and the overall throughput.
#
# Respects the DRYRUN environment variable; if set to 1, then
# logs the operation (with to and from path) and returns.
function gcs_util::upload() {
  local local_path=${1}
  local remote_path=${2}

  logging::emit "Will upload: ${local_path} to ${remote_path}"
  if [[ ${DRYRUN:-} -eq 1 ]]; then
    return
  fi

  # Track the number of bytes we upload.
  local bytes=$(du -s --bytes ${local_path} | cut -f 1 -d $'\t')

  # Do the upload
  local time_start=$(date +%s)
  gsutil -m cp ${local_path} ${remote_path}
  local time_end=$(date +%s)

  local time=$((time_end - time_start))

  logging::emit "Upload: ${bytes} bytes in ${time} seconds"
  logging::emit "Upload rate: $(( (bytes/1000/1000) / time )) MB/s"
}
readonly -f gcs_util::upload

# gcs_util::upload_log
#
# Copies the log file at the specified local path into Cloud Storage.
# This is largely syntactic sugar around "gsutil cp", but it does
# respects the DRYRUN environment variable; if set to 1, then
# logs the intended operation (with to and from path) and returns.
function gcs_util::upload_log() {
  local local_path=${1}
  local remote_path=${2}

  logging::emit "Upload log: ${local_path} to ${remote_path}"
  if [[ ${DRYRUN:-} -eq 1 ]]; then
    return
  fi

  gsutil cp ${local_path} ${remote_path}
}
readonly -f gcs_util::upload_log

# gcs_util::get_file_list
#
# Returns a list of matching objects at the specified remote path.
# This is strictly syntactic sugar around "gsutil ls".
# It does NOT respect the DRYRUN environment variable as the intent of
# this function is to be used specifically when DRYRUN is enabled (1).
function gcs_util::get_file_list() {
  local remote_path=${1}

  gsutil ls ${remote_path}
}
readonly -f gcs_util::get_file_list 
