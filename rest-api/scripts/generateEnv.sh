#!/usr/bin/env bash

#
# SPDX-License-Identifier: Apache-2.0
#

${AS_LOCAL_HOST:=true}

: "${TEST_NETWORK_PATIENT_HOME:=..}"
: "${TEST_NETWORK_DOCTOR_HOME:=../../DoctorNodeCreater/}"


# For Patients

: "${CONNECTION_PROFILE_FILE_PATORG:=${TEST_NETWORK_PATIENT_HOME}/network/organizations/peerOrganizations/patorg.patient.com/connection-patorg.json}"
: "${CERTIFICATE_FILE_PATORG:=${TEST_NETWORK_PATIENT_HOME}/network/organizations/peerOrganizations/patorg.patient.com/users/User1@patorg.patient.com/msp/signcerts/cert.pem}"
: "${PRIVATE_KEY_FILE_PATORG:=${TEST_NETWORK_PATIENT_HOME}/network/organizations/peerOrganizations/patorg.patient.com/users/User1@patorg.patient.com/msp/keystore/*_sk}"
: "${PEER_TLSCA_CERT_FILE_PATORG:=${TEST_NETWORK_PATIENT_HOME}/network/organizations/peerOrganizations/patorg.patient.com/tlsca/tlsca.patorg.patient.com-cert.pem}"
: "${PEER_TLSCA_CONTENT_PATORG:=$(cat ${PEER_TLSCA_CERT_FILE_PATORG})}"

# For Doctors

: "${CONNECTION_PROFILE_FILE_DOCORG:=${TEST_NETWORK_DOCTOR_HOME}/network/organizations/peerOrganizations/docorg.doctor.com/connection-docorg.json}"
: "${CERTIFICATE_FILE_DOCORG:=${TEST_NETWORK_DOCTOR_HOME}/network/organizations/peerOrganizations/docorg.doctor.com/users/User1@docorg.doctor.com/msp/signcerts/cert.pem}"
: "${PRIVATE_KEY_FILE_DOCORG:=${TEST_NETWORK_DOCTOR_HOME}/network/organizations/peerOrganizations/docorg.doctor.com/users/User1@docorg.doctor.com/msp/keystore/*_sk}"
: "${PEER_TLSCA_CERT_FILE_DOCORG:=${TEST_NETWORK_DOCTOR_HOME}/network/organizations/peerOrganizations/docorg.doctor.com/tlsca/tlsca.docorg.doctor.com-cert.pem}"
: "${PEER_TLSCA_CONTENT_DOCORG:=$(cat ${PEER_TLSCA_CERT_FILE_DOCORG})}"




cat << ENV_END > .env
# Generated .env file

LOG_LEVEL=debug
PORT=3100

HLF_CHANNEL_NAME = "patdoc-channel0"

HLF_CERTIFICATE_PATORG="$(cat ${CERTIFICATE_FILE_PATORG} | sed -e 's/$/\\n/' | tr -d '\r\n')"
HLF_PRIVATE_KEY_PATORG="$(cat ${PRIVATE_KEY_FILE_PATORG} | sed -e 's/$/\\n/' | tr -d '\r\n')"

HLF_CERTIFICATE_DOCORG="$(cat ${CERTIFICATE_FILE_DOCORG} | sed -e 's/$/\\n/' | tr -d '\r\n')"
HLF_PRIVATE_KEY_DOCORG="$(cat ${PRIVATE_KEY_FILE_DOCORG} | sed -e 's/$/\\n/' | tr -d '\r\n')"

REDIS_PORT=6379

EMAIL_PATORG="patorg-admin@patient.com"
PASSWORD_PATORG="patorgadmin123"

EMAIL_DOCORG="docrg-admin@doctor.com"
PASSWORD_DOCORG="docorgadmin123"

PATORG_APIKEY=$(uuidgen)
DOCORG_APIKEY=$(uuidgen)

NODE_ENV="development"
ENV_END
 
if [ "${AS_LOCAL_HOST}" = "true" ]; then

cat << LOCAL_HOST_END >> .env
AS_LOCAL_HOST=true

HLF_CONNECTION_PROFILE_PATORG=$(cat ${CONNECTION_PROFILE_FILE_PATORG} | jq -c .)
HLF_CONNECTION_PROFILE_DOCORG=$(cat ${CONNECTION_PROFILE_FILE_DOCORG} | jq -c .)

REDIS_HOST=localhost

LOCAL_HOST_END

elif [ "${AS_LOCAL_HOST}" = "false" ]; then

cat << WITH_HOSTNAME_END >> .env
AS_LOCAL_HOST=false

HLF_CONNECTION_PROFILE_PATORG=$(cat ${CONNECTION_PROFILE_FILE_PATORG} | jq -c .)

HLF_CONNECTION_PROFILE_DOCORG=$(cat ${CONNECTION_PROFILE_FILE_DOCORG} | jq -c .)

REDIS_HOST=redis

WITH_HOSTNAME_END

fi
