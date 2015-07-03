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
#  * Set LOGGING_LOG_FILE
#  * Call logging::log to write messages to the log
#  * Call logging::emit to write to stdout and to the log

# logging::log
#
# The log function will echo the input parameters to the LOGGING_LOG_FILE
function logging::log() {
  if [[ -n ${LOGGING_LOG_FILE:-} ]]; then
    echo "${@}" >> ${LOGGING_LOG_FILE}
  fi
}
readonly -f logging::log

# logging::emit
#
# The emit function will echo the input parameters to stdout
# and will also emit the input to the LOGGING_LOG_FILE
function logging::emit() {
  echo "${@}"
  logging::log ${@}
}
readonly -f logging::emit
