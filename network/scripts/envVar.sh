#!/bin/bash



# imports
. scripts/utils.sh

# network/

# ENV VARIABLES
export DOCORG_PWD=../../DoctorNodeCreater/network
export CORE_PEER_TLS_ENABLED=true
export PEER0_PATORG_CA=${PWD}/organizations/peerOrganizations/patorg.patient.com/peers/peer${PEER_PATIENT_NUMBER}.patorg.patient.com/tls/ca.crt
export PEER0_DOCORG_CA=${DOCORG_PWD}/organizations/peerOrganizations/docorg.doctor.com/tlsca/tlsca.docorg.doctor.com-cert.pem

export ORDERER_CA=${PWD}/organizations/ordererOrganizations/patient.com/tlsca/tlsca.patient.com-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/patient.com/orderers/orderer.patient.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/patient.com/orderers/orderer.patient.com/tls/server.key

export PEER_CA=${PWD}/organizations/peerOrganizations/patorg.patient.com/tlsca/tlsca.patorg.patient.com-cert.pem
export PEER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/peerOrganizations/patorg.patient.com/peers/peer${PEER_PATIENT_NUMBER}.patorg.patient.com/tls/server.crt
export PEER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/peerOrganizations/patorg.patient.com/peers/peer${PEER_PATIENT_NUMBER}.patorg.patient.com/tls/server.key

# Set environment variables for the peer org
setGlobals0() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  infoln "Using organization ${USING_ORG}"
  if [ $USING_ORG = "patorg" ]; then
    export CORE_PEER_LOCALMSPID="PatOrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_PATORG_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/patorg.patient.com/users/Admin@patorg.patient.com/msp
    export CORE_PEER_ADDRESS=localhost:${PEER_PATIENT_PORT}
  elif [ $USING_ORG = "docorg" ]; then
    export CORE_PEER_LOCALMSPID="DocOrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_DOCORG_CA
    export CORE_PEER_MSPCONFIGPATH=${DOCORG_PWD}/organizations/peerOrganizations/docorg.doctor.com/users/Admin@docorg.doctor.com/msp
    export CORE_PEER_ADDRESS=localhost:${PEER_DOCTOR_PORT}  
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

setGlobalsCLI0() {
  setGlobals0 $1

  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  if [ $USING_ORG = "patorg" ]; then
    export CORE_PEER_ADDRESS=peer${PEER_PATIENT_NUMBER}.patorg.patient.com:${PEER_PATIENT_PORT}
  else
    errorln "ORG Unknown"
  fi
}


verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
