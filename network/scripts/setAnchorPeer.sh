#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# import utils
. scripts/envVar.sh
. scripts/configUpdate.sh


# NOTE: this must be run in a CLI container since it requires jq and configtxlator 
createAnchorPeerUpdate() {
  infoln "Fetching channel config for channel $CHANNEL_NAME"
  fetchChannelConfig $ORG $CHANNEL_NAME ${CORE_PEER_LOCALMSPID}config.json

  infoln "Generating anchor peer update transaction for ${ORG} on channel $CHANNEL_NAME"

  if [ $ORG = "patorg" ]; then
    export HOST=peer${PEER_PATIENT_NUMBER}.patorg.patient.com
    export PORT=${PEER_PATIENT_PORT}
  elif [ $ORG = "docorg" ]; then
    export HOST=peer${PEER_DOCTOR_NUMBER}.docorg.doctor.com
    export PORT=${PEER_DOCTOR_PORT} # ${PEER_PATIENT_PORT}
  else
    errorln "${ORG} unknown"
  fi

  infoln "Host is ${HOST} and PORT is ${PORT}"

  set -x
  # Modify the configuration to append the anchor peer 
  jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'${HOST}'","port": '${PORT}'}]},"version": "0"}}' ${CORE_PEER_LOCALMSPID}config.json > ${CORE_PEER_LOCALMSPID}modified_config.json
  { set +x; } 2>/dev/null

  # Compute a config update, based on the differences between 
  # {orgmsp}config.json and {orgmsp}modified_config.json, write
  # it as a transaction to {orgmsp}anchors.tx
  createConfigUpdate ${CHANNEL_NAME} ${CORE_PEER_LOCALMSPID}config.json ${CORE_PEER_LOCALMSPID}modified_config.json ${CORE_PEER_LOCALMSPID}anchors.tx
}

updateAnchorPeer() {
  if [ $ORG = "patorg" ]; then
    peer channel update -o orderer.patient.com:7060 --ordererTLSHostnameOverride orderer.patient.com -c $CHANNEL_NAME -f ${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile "$ORDERER_CA" >&log.txt
  elif [ $ORG = "docorg" ]; then
    peer channel update -o orderer.doctor.com:7050 --ordererTLSHostnameOverride orderer.doctor.com -c $CHANNEL_NAME -f ${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile "$DOC_ORDERER_CA" >&log.txt
  fi
  
  res=$?
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  successln "Anchor peer set for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME'"
}

ORG=$1
CHANNEL_NAME=$2
PEER_NUMBER=$3
PEER_PORT=$4

if [ $ORG = "patorg" ]; then
  export PEER_PATIENT_NUMBER=$PEER_NUMBER
  export PEER_PATIENT_PORT=$PEER_PORT
elif [ $ORG = "docorg" ]; then
  export PEER_DOCTOR_NUMBER=$PEER_NUMBER
  export PEER_DOCTOR_PORT=$PEER_PORT
fi


setGlobalsCLI0 $ORG

infoln "ORGMSP=${CORE_PEER_LOCALMSPID}, PORT=${PEER_PORT} , PEER0_DOCORG_CA=${PEER0_DOCORG_CA}, CORE_PEER_MSPCONFIGPATH=${CORE_PEER_MSPCONFIGPATH}"

createAnchorPeerUpdate 

updateAnchorPeer 
