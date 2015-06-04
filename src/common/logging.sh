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

# logging.sh
#
# Provides basic logging services.
# Client's of this utility script should:
#  * Set BIGTOOLS_LOG_FILE
#  * Call bigtools_log::log to write messages to the log
#  * Call bigtools_log::emit to write to stdout and to the log

declare BIGTOOLS_LOG_FILE=

# bigtools_log::log
#
# The log function will echo the input parameters to the BIGTOOLS_LOG_FILE
function bigtools_log::log() {
  if [[ -n ${BIGTOOLS_LOG_FILE} ]]; then
    echo "${@}" >> ${BIGTOOLS_LOG_FILE}
  fi
}
readonly -f bigtools_log::log

# bigtools_log::emit
#
# The emit function will echo the input parameters to stdout
# and will also emit the input to the BIGTOOLS_LOG_FILE
function bigtools_log::emit() {
  echo "${@}"
  bigtools_log::log ${@}
}
readonly -f bigtools_log::emit
