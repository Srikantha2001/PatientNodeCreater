#!/bin/bash

# imports  
. scripts/envVar.sh
. scripts/utils.sh

CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"

: ${CHANNEL_NAME:="patdoc-channel${PEER_PATIENT_NUMBER}"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="true"}

: ${CONTAINER_CLI:="docker"}
: ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}

infoln "Using ${CONTAINER_CLI} and ${CONTAINER_CLI_COMPOSE}"

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createChannelGenesisBlock() {
	which configtxgen
	if [ "$?" -ne 0 ]; then
		fatalln "configtxgen tool not found."
	fi
	set -x
	configtxgen -profile TwoOrgsApplicationGenesis -outputBlock ./channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
	res=$?
	{ set +x; } 2>/dev/null
  verifyResult $res "Failed to generate channel configuration transaction..."
}

createChannel() {
	setGlobals0 "patorg"
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		osnadmin channel join --channelID $CHANNEL_NAME --config-block ./channel-artifacts/${CHANNEL_NAME}.block -o localhost:7153 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"

	setGlobals0 "docorg"
	rc=1
	COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		osnadmin channel join --channelID $CHANNEL_NAME --config-block ./channel-artifacts/${CHANNEL_NAME}.block -o localhost:7053 --ca-file "$DOC_ORDERER_CA" --client-cert "$DOC_ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$DOC_ORDERER_ADMIN_TLS_PRIVATE_KEY" >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
}

# joinChannel ORG
joinChannel() {
	FABRIC_CFG_PATH=$PWD/../config/
	ORG=$1
	PEERNAME=$2
	infoln "Joining PEER${PEERNAME} to Channel ${CHANNEL_NAME}"
	setGlobals0 $ORG
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
	sleep $DELAY
	set -x
	peer channel join -b $BLOCKFILE>&log.txt
	res=$?
	{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "After $MAX_RETRY attempts, peer${PEERNAME}.${ORG} has failed to join channel '$CHANNEL_NAME' "
}

joinChannelDoctor() {
	FABRIC_CFG_PATH=$PWD/../config/
	ORG=$1
	PEERNAME=$2
	infoln "Joining DOCTOR${PEERNAME} to Channel ${CHANNEL_NAME}"
	setGlobals0 $ORG
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
	sleep $DELAY
	set -x
	peer channel join -b $BLOCKFILE >&log.txt
	res=$?
	{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "After $MAX_RETRY attempts, peer${PEERNAME}.${ORG} has failed to join channel '$CHANNEL_NAME' "
}

setAnchorPeer() {
  ORG=$1
  CLI_PEER_NUMBER=$2
  CLI_PEER_PORT=$3
  ${CONTAINER_CLI} exec cli ./scripts/setAnchorPeer.sh $ORG $CHANNEL_NAME $CLI_PEER_NUMBER $CLI_PEER_PORT
}

FABRIC_CFG_PATH=${PWD}/configtx

## Create channel genesis block
infoln "Generating channel genesis block '${CHANNEL_NAME}.block'"
createChannelGenesisBlock

FABRIC_CFG_PATH=$PWD/../config/
BLOCKFILE="./channel-artifacts/${CHANNEL_NAME}.block"

## Create channel
infoln "Creating channel ${CHANNEL_NAME}"
createChannel
successln "Channel '$CHANNEL_NAME' created"

## Join all the peers to the channel
infoln "Joining patient peer${PEER_PATIENT_NUMBER}  to the channel..."
joinChannel "patorg" ${PEER_PATIENT_NUMBER}

# infoln "Joining doctor peer to the channel ..."
joinChannelDoctor "docorg" 0

setGlobals0 "patorg" 

## Set the anchor peers for each org in the channel
infoln "Setting anchor peer for patorg..."
setAnchorPeer "patorg" ${PEER_PATIENT_NUMBER} ${PEER_PATIENT_PORT}
# setAnchorPeer "docorg" ${PEER_DOCTOR_NUMBER}  ${PEER_DOCTOR_PORT}

successln "Channel '$CHANNEL_NAME' joined"
