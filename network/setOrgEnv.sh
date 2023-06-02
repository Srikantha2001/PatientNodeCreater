#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0




# default to using patorg
ORG=${1:-patorg}

# Exit on first error, print all commands.
set -e
set -o pipefail

# Where am I?
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

ORDERER_CA=${DIR}/network/organizations/ordererOrganizations/patient.com/tlsca/tlsca.patient.com-cert.pem
PEER0_PATORG_CA=${DIR}/network/organizations/peerOrganizations/patorg.patient.com/tlsca/tlsca.patorg.patient.com-cert.pem


if [[ ${ORG,,} == "patorg" ]; then

   CORE_PEER_LOCALMSPID=PatOrgMSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/network/organizations/peerOrganizations/patorg.patient.com/users/Admin@patorg.patient.com/msp
   CORE_PEER_ADDRESS=localhost:${PEER_PATIENT_PORT}
   CORE_PEER_TLS_ROOTCERT_FILE=${DIR}/network/organizations/peerOrganizations/patorg.patient.com/tlsca/tlsca.patorg.patient.com-cert.pem

else
   echo "Unknown \"$ORG\", please choose patorg/Digibank or PatOrg2/Magnetocorp"
   echo
   exit 1
fi

# output the variables that need to be set
echo "CORE_PEER_TLS_ENABLED=true"
echo "ORDERER_CA=${ORDERER_CA}"
echo "PEER0_PATORG_CA=${PEER0_PATORG_CA}"

echo "CORE_PEER_MSPCONFIGPATH=${CORE_PEER_MSPCONFIGPATH}"
echo "CORE_PEER_ADDRESS=${CORE_PEER_ADDRESS}"
echo "CORE_PEER_TLS_ROOTCERT_FILE=${CORE_PEER_TLS_ROOTCERT_FILE}"

echo "CORE_PEER_LOCALMSPID=${CORE_PEER_LOCALMSPID}"
