# PatientNodeCreater

This repository contain the code for the creation of a new Hyperledger fabric Peer. This involve the following procedures
1. Creation of Cryptographic material using the Fabric CA for current Patient Peer
2. Creation of New Channel with name as `patdoc-channel-<number>` 
3. Joining the current patient peer and corresponding doctor peer to the channel.
4. Invoking the chaincode in the channel

## Prerequisite

Before running this project,The containers related to corresponding doctors should be up and running

## Setup

For setup, just execute the following command
```Shell
python3 patientNodeCreaterScript.py

```
