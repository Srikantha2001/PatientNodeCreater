#!/bin/bash


. scripts/envVar.sh

fetchChannelConfig() {
  ORG=$1
  CHANNEL=$2
  OUTPUT=$3

  setGlobals0 $ORG

  infoln "Fetching the most recent configuration block for the channel"
  
  if [ $ORG = "patorg" ]; then
    set -x
    peer channel fetch config config_block.pb -o orderer.patient.com:7060 --ordererTLSHostnameOverride orderer.patient.com -c $CHANNEL --tls --cafile "$ORDERER_CA"
    { set +x; } 2>/dev/null
  elif [ $ORG = "docorg" ]; then
    setGlobalsCLI0 $ORG
    set -x
    peer channel fetch config config_block.pb -o orderer.doctor.com:7050 --ordererTLSHostnameOverride orderer.doctor.com -c $CHANNEL --tls --cafile "$DOC_ORDERER_CA"
    { set +x; } 2>/dev/null
  fi

  infoln "Decoding config block to JSON and isolating config to ${OUTPUT}"
  set -x
  configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
  jq .data.data[0].payload.data.config config_block.json >"${OUTPUT}"
  { set +x; } 2>/dev/null
}

createConfigUpdate() {
  CHANNEL=$1
  ORIGINAL=$2
  MODIFIED=$3
  OUTPUT=$4

  set -x
  configtxlator proto_encode --input "${ORIGINAL}" --type common.Config --output original_config.pb
  configtxlator proto_encode --input "${MODIFIED}" --type common.Config --output modified_config.pb
  configtxlator compute_update --channel_id "${CHANNEL}" --original original_config.pb --updated modified_config.pb --output config_update.pb
  configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . >config_update_in_envelope.json
  configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output "${OUTPUT}"
  { set +x; } 2>/dev/null
}

signConfigtxAsPeerOrg() {
  ORG=$1
  CONFIGTXFILE=$2
  setGlobals0 $ORG
  set -x
  peer channel signconfigtx -f "${CONFIGTXFILE}"
  { set +x; } 2>/dev/null
}
