#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${PPORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        -e "s/\${PEER_PATIENT_NUMBER}/$6/" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${PPORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

echo "GENERATION started for PEER ${PEER_PATIENT_NUMBER}"

ORG="patorg"
PPORT=${PEER_PATIENT_PORT}  
CAPORT=7154
PEERPEM=organizations/peerOrganizations/patorg.patient.com/tlsca/tlsca.patorg.patient.com-cert.pem
CAPEM=organizations/peerOrganizations/patorg.patient.com/ca/ca.patorg.patient.com-cert.pem
PEERNUM=${PEER_PATIENT_NUMBER}

if [ ${PEER_PATIENT_NUMBER} == '0' ]; then
    echo "$(json_ccp $ORG $PPORT $CAPORT $PEERPEM $CAPEM $PEERNUM)" > organizations/peerOrganizations/patorg.patient.com/connection-patorg.json
else
    echo "$(json_ccp $ORG $PPORT $CAPORT $PEERPEM $CAPEM $PEERNUM)" > organizations/peerOrganizations/patorg.patient.com/temp-connection-patorg.json
fi

echo "$(yaml_ccp $ORG $PPORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/patorg.patient.com/connection-patorg.yaml