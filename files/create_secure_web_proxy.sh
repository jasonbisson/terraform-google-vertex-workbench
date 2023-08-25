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
  variables=(PROJECT_ID NETWORK_NAME REGION DOMAINNAME CERTIFICATE_NAME KEY_NAME POLICY_NAME POLICY_FILE RULE_NAME RULE_FILE GATEWAY_FILE GATEWAY_NAME URL_NAME URL_FILE)

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

function create_certificate() {
  openssl req -x509 -newkey rsa:2048 \
    -keyout $HOME/${KEY_NAME}.pem \
    -out $HOME/${CERTIFICATE_NAME}.pem -days 365 \
    -subj '/CN='${DOMAINNAME}'' -nodes -addext \
    "subjectAltName=DNS:${DOMAINNAME}"
  check_exit

  gcloud certificate-manager certificates create $CERTIFICATE_NAME --certificate-file="$HOME/${CERTIFICATE_NAME}.pem" \
    --private-key-file="$HOME/${KEY_NAME}.pem" --location=${REGION}
  check_exit
}

create_secure_web_gateway_policy() {

  cat <<EOF >$HOME/${POLICY_FILE}.template
description: Secure Web Proxy policy without TLS inspection
name: projects/PROJECT_ID/locations/REGION/gatewaySecurityPolicies/POLICY_NAME
EOF
  check_exit
  cp $HOME/${POLICY_FILE}.template $HOME/$POLICY_FILE
  check_exit
  sed -i '' "s/PROJECT_ID/${PROJECT_ID}/" $HOME/$POLICY_FILE
  check_exit
  sed -i '' "s/REGION/${REGION}/" $HOME/$POLICY_FILE
  check_exit
  sed -i '' "s/POLICY_NAME/${POLICY_NAME}/" $HOME/$POLICY_FILE
  check_exit

  gcloud network-security gateway-security-policies import ${POLICY_NAME} --source="$HOME/${POLICY_FILE}" --location=${REGION}
  check_exit
}

function create_url_list() {
cat <<EOF >$HOME/${URL_FILE}.template
name: projects/PROJECT_ID/locations/REGION/urlLists/URL_NAME
values:
  - "github.com"
  - "pypi.org"
  - "pypi.python.org"
  - "files.pythonhosted.org"
  - "packaging.python.org"
EOF
check_exit
cp $HOME/${URL_FILE}.template $HOME/${URL_FILE}
check_exit
sed -i '' "s/PROJECT_ID/${PROJECT_ID}/" $HOME/${URL_FILE}
check_exit
sed -i '' "s/REGION/${REGION}/" $HOME/${URL_FILE}
check_exit
sed -i '' "s/URL_NAME/${URL_NAME}/" $HOME/${URL_FILE}
check_exit

gcloud network-security url-lists import ${URL_NAME} --location=${REGION} --project=${PROJECT_ID} --source="$HOME/${URL_FILE}"

}

function create_rule_to_secure_web_gateway_policy() {

cat <<EOF >$HOME/${RULE_FILE}.template
name: projects/PROJECT_ID/locations/REGION/gatewaySecurityPolicies/POLICY_NAME/rules/RULE_NAME
description: Allow external repositories
enabled: true
priority: 1
basicProfile: ALLOW
sessionMatcher: "inUrlList(host(), 'projects/PROJECT_ID/locations/REGION/urlLists/URL_NAME')"
EOF
  check_exit
  cp $HOME/${RULE_FILE}.template $HOME/${RULE_FILE}
  check_exit
  sed -i '' "s/PROJECT_ID/${PROJECT_ID}/" $HOME/${RULE_FILE}
  check_exit
  sed -i '' "s/REGION/${REGION}/" $HOME/${RULE_FILE}
  check_exit
  sed -i '' "s/POLICY_NAME/${POLICY_NAME}/" $HOME/${RULE_FILE}
  check_exit
  sed -i '' "s/RULE_NAME/${RULE_NAME}/" $HOME/${RULE_FILE}
  check_exit
  sed -i '' "s/URL_NAME/${URL_NAME}/" $HOME/${RULE_FILE}
  check_exit
  gcloud network-security gateway-security-policies rules import ${RULE_NAME} --source=$HOME/${RULE_FILE} --location=${REGION} --gateway-security-policy=${POLICY_NAME}
  check_exit

}

function create_secure_web_gateway() {

cat <<EOF >$HOME/$GATEWAY_FILE.template
name: projects/PROJECT_ID/locations/REGION/gateways/GATEWAY_NAME
type: SECURE_WEB_GATEWAY
ports: [443]
certificateUrls: ["projects/PROJECT_ID/locations/REGION/certificates/CERTIFICATE_NAME"]
gatewaySecurityPolicy: projects/PROJECT_ID/locations/REGION/gatewaySecurityPolicies/POLICY_NAME
network: projects/PROJECT_ID/global/networks/NETWORK_NAME
subnetwork: projects/PROJECT_ID/regions/REGION/subnetworks/SUBNET_NAME
scope: samplescope
EOF
check_exit

  cp $HOME/$GATEWAY_FILE.template $HOME/$GATEWAY_FILE
  check_exit
  sed -i '' "s/PROJECT_ID/${PROJECT_ID}/" $HOME/$GATEWAY_FILE
  check_exit
  sed -i '' "s/REGION/${REGION}/" $HOME/$GATEWAY_FILE
  check_exit
  sed -i '' "s/POLICY_NAME/${POLICY_NAME}/" $HOME/$GATEWAY_FILE
  check_exit
  sed -i '' "s/GATEWAY_NAME/${GATEWAY_NAME}/" $HOME/$GATEWAY_FILE
  check_exit
  sed -i '' "s/CERTIFICATE_NAME/${CERTIFICATE_NAME}/" $HOME/$GATEWAY_FILE
  check_exit
  sed -i '' "s/NETWORK_NAME/${NETWORK_NAME}/" $HOME/$GATEWAY_FILE
  check_exit
  sed -i '' "s/SUBNET_NAME/${SUBNET_NAME}/" $HOME/$GATEWAY_FILE
  check_exit

  gcloud network-services gateways import $GATEWAY_NAME --source=$HOME/$GATEWAY_FILE --location=${REGION}
  check_exit

}

check_empty_variables
create_certificate
create_secure_web_gateway_policy
create_url_list
create_rule_to_secure_web_gateway_policy
create_secure_web_gateway
