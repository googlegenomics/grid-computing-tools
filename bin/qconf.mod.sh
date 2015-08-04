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

# qconf.mod.sh
#
# Variant of the script suggested here:
#  http://gridscheduler.sourceforge.net/howto/scripting.html
#
# to allow for setting configuration options programmatically.
#
# Example:
#   qconf.mod.sh -mconf global reschedule_unknown 00:05:00
 
set -o errexit
set -o nounset

if [[ $# -eq 0 ]]; then
  echo "Usage: ${0} [qconf_command] [host|global] [qconf_param] [qconf_value]"
  exit 1
fi

# This script gets invoked directly by the user with the command-line
# noted above.
#
# The script then sets itself as the EDITOR and executes "qconf".
# qconf will then call this script with one command-line parameter
# (a temporary file name).

if [[ -z ${QCONF_PARAMETER:-} ]]; then
  readonly COMMAND=${1}
  readonly HOST=${2}
  export QCONF_PARAMETER=${3}
  export QCONF_VALUE=${4}

  EDITOR=${0} \
    qconf ${COMMAND} ${HOST}
else
  # Sleep 1 second to ensure that the file modification time changes
  sleep 1

  # Update the temp file passed on the command-line by qconf
  readonly QCONF_TEMP_FILE=${1}
  sed -i \
    -e "/^${QCONF_PARAMETER} /d;\$a${QCONF_PARAMETER} ${QCONF_VALUE}" \
    ${QCONF_TEMP_FILE}
fi

