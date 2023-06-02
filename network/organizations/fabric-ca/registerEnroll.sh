#!/bin/bash

function createPatOrg() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/patorg.patient.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/patorg.patient.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7154 --caname ca-patorg --tls.certfiles "${PWD}/organizations/fabric-ca/patorg/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7154-ca-patorg.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7154-ca-patorg.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7154-ca-patorg.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7154-ca-patorg.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/patorg.patient.com/msp/config.yaml"

  # Copy patorg's CA cert to patorg's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/peerOrganizations/patorg.patient.com/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/patorg/ca-cert.pem" "${PWD}/organizations/peerOrganizations/patorg.patient.com/msp/tlscacerts/ca.crt"

  # Copy patorg's CA cert to patorg's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/patorg.patient.com/tlsca"
  cp "${PWD}/organizations/fabric-ca/patorg/ca-cert.pem" "${PWD}/organizations/peerOrganizations/patorg.patient.com/tlsca/tlsca.patorg.patient.com-cert.pem"

  # Copy patorg's CA cert to patorg's /ca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/patorg.patient.com/ca"
  cp "${PWD}/organizations/fabric-ca/patorg/ca-cert.pem" "${PWD}/organizations/peerOrganizations/patorg.patient.com/ca/ca.patorg.patient.com-cert.pem"

  
  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-patorg --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/patorg/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-patorg --id.name patorgadmin --id.secret patorgadminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/patorg/ca-cert.pem"
  { set +x; } 2>/dev/null


  infoln "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:7154 --caname ca-patorg -M "${PWD}/organizations/peerOrganizations/patorg.patient.com/users/User1@patorg.patient.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/patorg/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/patorg.patient.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/patorg.patient.com/users/User1@patorg.patient.com/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://patorgadmin:patorgadminpw@localhost:7154 --caname ca-patorg -M "${PWD}/organizations/peerOrganizations/patorg.patient.com/users/Admin@patorg.patient.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/patorg/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/patorg.patient.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/patorg.patient.com/users/Admin@patorg.patient.com/msp/config.yaml"

}



function createOrderer() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/ordererOrganizations/patient.com

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/patient.com

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:9154 --caname pat-ca-orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9154-pat-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9154-pat-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9154-pat-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9154-pat-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/ordererOrganizations/patient.com/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy orderer org's CA cert to orderer org's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/ordererOrganizations/patient.com/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem" "${PWD}/organizations/ordererOrganizations/patient.com/msp/tlscacerts/tlsca.patient.com-cert.pem"

  # Copy orderer org's CA cert to orderer org's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/ordererOrganizations/patient.com/tlsca"
  cp "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem" "${PWD}/organizations/ordererOrganizations/patient.com/tlsca/tlsca.patient.com-cert.pem"

  infoln "Registering orderer"
  set -x
  fabric-ca-client register --caname pat-ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the orderer admin"
  set -x
  fabric-ca-client register --caname pat-ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the orderer msp"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9154 --caname pat-ca-orderer -M "${PWD}/organizations/ordererOrganizations/patient.com/orderers/orderer.patient.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/patient.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/patient.com/orderers/orderer.patient.com/msp/config.yaml"

  infoln "Generating the orderer-tls certificates, use --csr.hosts to specify Subject Alternative Names"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9154 --caname pat-ca-orderer -M "${PWD}/organizations/ordererOrganizations/patient.com/orderers/orderer.patient.com/tls" --enrollment.profile tls --csr.hosts orderer.patient.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the orderer's tls directory that are referenced by orderer startup config
  cp "${PWD}/organizations/ordererOrganizations/patient.com/orderers/orderer.patient.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/patient.com/orderers/orderer.patient.com/tls/ca.crt"
  cp "${PWD}/organizations/ordererOrganizations/patient.com/orderers/orderer.patient.com/tls/signcerts/"* "${PWD}/organizations/ordererOrganizations/patient.com/orderers/orderer.patient.com/tls/server.crt"
  cp "${PWD}/organizations/ordererOrganizations/patient.com/orderers/orderer.patient.com/tls/keystore/"* "${PWD}/organizations/ordererOrganizations/patient.com/orderers/orderer.patient.com/tls/server.key"

  # Copy orderer org's CA cert to orderer's /msp/tlscacerts directory (for use in the orderer MSP definition)
  mkdir -p "${PWD}/organizations/ordererOrganizations/patient.com/orderers/orderer.patient.com/msp/tlscacerts"
  cp "${PWD}/organizations/ordererOrganizations/patient.com/orderers/orderer.patient.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/patient.com/orderers/orderer.patient.com/msp/tlscacerts/tlsca.patient.com-cert.pem"

  infoln "Generating the admin msp"
  set -x
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9154 --caname pat-ca-orderer -M "${PWD}/organizations/ordererOrganizations/patient.com/users/Admin@patient.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/patient.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/patient.com/users/Admin@patient.com/msp/config.yaml"
}

function createPatPeer(){
  
  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/patorg.patient.com/

  infoln "Registering peer${PEER_PATIENT_NUMBER}"
  set -x
  fabric-ca-client register --caname ca-patorg --id.name peer${PEER_PATIENT_NUMBER} --id.secret peer${PEER_PATIENT_NUMBER}pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/patorg/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the peer${PEER_PATIENT_NUMBER} msp"
  set -x
  fabric-ca-client enroll -u https://peer${PEER_PATIENT_NUMBER}:peer${PEER_PATIENT_NUMBER}pw@localhost:7154 --caname ca-patorg -M "${PWD}/organizations/peerOrganizations/patorg.patient.com/peers/peer${PEER_PATIENT_NUMBER}.patorg.patient.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/patorg/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/patorg.patient.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/patorg.patient.com/peers/peer${PEER_PATIENT_NUMBER}.patorg.patient.com/msp/config.yaml"

  infoln "Generating the peer${PEER_PATIENT_NUMBER}-tls certificates, use --csr.hosts to specify Subject Alternative Names"
  set -x
  fabric-ca-client enroll -u https://peer${PEER_PATIENT_NUMBER}:peer${PEER_PATIENT_NUMBER}pw@localhost:7154 --caname ca-patorg -M "${PWD}/organizations/peerOrganizations/patorg.patient.com/peers/peer${PEER_PATIENT_NUMBER}.patorg.patient.com/tls" --enrollment.profile tls --csr.hosts peer${PEER_PATIENT_NUMBER}.patorg.patient.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/patorg/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
  cp "${PWD}/organizations/peerOrganizations/patorg.patient.com/peers/peer${PEER_PATIENT_NUMBER}.patorg.patient.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/patorg.patient.com/peers/peer${PEER_PATIENT_NUMBER}.patorg.patient.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/patorg.patient.com/peers/peer${PEER_PATIENT_NUMBER}.patorg.patient.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/patorg.patient.com/peers/peer${PEER_PATIENT_NUMBER}.patorg.patient.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/patorg.patient.com/peers/peer${PEER_PATIENT_NUMBER}.patorg.patient.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/patorg.patient.com/peers/peer${PEER_PATIENT_NUMBER}.patorg.patient.com/tls/server.key"
}