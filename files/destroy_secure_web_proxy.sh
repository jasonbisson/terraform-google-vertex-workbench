#!/bin/bash
#set -x
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[[ "$#" -ne 2 ]] && {
  echo "Usage : $(basename "$0") --project_id <Google Cloud Project ID >"
  exit 1
}
[[ "$1" = "--project_id" ]] && export PROJECT_ID=$2

source source.env

function check_empty_variables() {
  variables=(PROJECT_ID NETWORK_NAME REGION DOMAINNAME CERTIFICATE_NAME KEY_NAME POLICY_NAME POLICY_FILE RULE_NAME RULE_FILE GATEWAY_FILE GATEWAY_NAME)

  for variable in "${variables[@]}"; do
    if [ -z "${!variable}" ]; then
      printf "ERROR: Required variable $variable is either empty or unset.\n\n"
      printf "Update required vairable $variable with a value and run script again. \n\n"
      exit
    fi
  done

}

function check_exit() {
  # Check if the exit code is 0
  if [[ $? -ne 0 ]]; then
    echo "Error occurred"
    exit 1
  fi
}

function destroy_secure_web_gateway() {
  gcloud network-services gateways delete ${GATEWAY_NAME} --location=${REGION}
  check_exit
}

function destroy_url_list() {
  gcloud network-security url-lists delete ${URL_NAME} --location=${REGION} 
  check_exit
}

function destroy_rule_to_secure_web_gateway_policy() {
  gcloud network-security gateway-security-policies rules delete ${RULE_NAME} --location=${REGION} --gateway-security-policy=${POLICY_NAME}
  check_exit
}

function destroy_secure_web_gateway_policy() {
  gcloud network-security gateway-security-policies delete ${POLICY_NAME} --location=${REGION}
  check_exit
}

function destroy_certificate() {
  gcloud certificate-manager certificates delete ${CERTIFICATE_NAME} --location=$REGION
  check_exit
}

check_empty_variables
#destroy_secure_web_gateway
destroy_url_list
exit
destroy_rule_to_secure_web_gateway_policy
destroy_secure_web_gateway_policy
destroy_certificate
