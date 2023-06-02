import pandas as pd
import os
import subprocess
import shlex
import yaml


# Loading of Yaml files

with open('./compose/compose-test-net-2.yaml', 'r') as file:
    compose_data = yaml.safe_load(file)


with open('./organizations/cryptogen/crypto-config-patorg.yaml', 'r') as file:
    config_data = yaml.safe_load(file)


# reading the file where variables are stored
df = pd.read_csv('variable.csv')

# Creating a dictionary to get all environment variable values
env_dict={}
for index in range(len(df.index)):
    env_dict[df['KeyColumn'].iloc[index]] =df['DataColumn'].iloc[index]

# ------------------------------------------------------------------------------------
# Do all modification for the environement variables here
#-------------------------------------------------------------------------------------

os.environ['PEER_PATIENT_NUMBER'] = str(env_dict['peer_number'])
os.environ['PEER_PATIENT_PORT'] = str(env_dict["peer_port"])
os.environ['NEXT_PEER_PORT_CC']=str(env_dict['peer_port']+1)
os.environ['OPER_LISTEN_PORT']=str(env_dict['listen_port'])

os.environ['PEER_DOCTOR_PORT'] = '10000'
os.environ['PEER_DOCTOR_NUMBER'] = '0'

newpeer = {
    'command':'peer node start',
    'container_name':'peer'+str(env_dict['peer_number'])+'.patorg.patient.com',
    'environment':[
        'FABRIC_LOGGING_SPEC=INFO',
        'CORE_PEER_TLS_ENABLED=true',
        'CORE_PEER_PROFILE_ENABLED=false',
        'CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt',
        'CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key',
        'CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt',
        'CORE_PEER_ID=peer'+str(env_dict['peer_number'])+'.patorg.patient.com',
        'CORE_PEER_ADDRESS=peer'+str(env_dict['peer_number'])+'.patorg.patient.com:${PEER_PATIENT_PORT}',
        'CORE_PEER_LISTENADDRESS=0.0.0.0:${PEER_PATIENT_PORT}',
        'CORE_PEER_CHAINCODEADDRESS=peer'+str(env_dict['peer_number'])+'.patorg.patient.com:${NEXT_PEER_PORT_CC}',
        'CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:${NEXT_PEER_PORT_CC}',
        'CORE_PEER_GOSSIP_BOOTSTRAP=peer'+str(env_dict['peer_number'])+'.patorg.patient.com:${PEER_PATIENT_PORT}',
        'CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer'+str(env_dict['peer_number'])+'.patorg.patient.com:${PEER_PATIENT_PORT}',
        'CORE_PEER_LOCALMSPID=PatOrgMSP',
        'CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp',
        'CORE_OPERATIONS_LISTENADDRESS=peer'+str(env_dict['peer_number'])+'.patorg.patient.com:${OPER_LISTEN_PORT}',
        'CORE_METRICS_PROVIDER=prometheus',
        'CHAINCODE_AS_A_SERVICE_BUILDER_CONFIG={"peername":"peer'+str(env_dict['peer_number'])+'patorg"}',
        'CORE_CHAINCODE_EXECUTETIMEOUT=300s', 
    ],
    'image': 'hyperledger/fabric-peer:latest',
    'labels': {
        'service': 'hyperledger-fabric',
    },
    'networks': ['test'],
    'ports': [
        '${PEER_PATIENT_PORT}:${PEER_PATIENT_PORT}',
        '${OPER_LISTEN_PORT}:${OPER_LISTEN_PORT}',
    ],
    'volumes': [
        '../organizations/peerOrganizations/patorg.patient.com/peers/peer'+str(env_dict['peer_number'])+'.patorg.patient.com:/etc/hyperledger/fabric',
        'peer'+str(env_dict['peer_number'])+'.patorg.patient.com:/var/hyperledger/production',
    ],
    'working_dir': '/root',
}

new_peer_config = {
    'Name': 'patorg',
    'Domain': 'patorg.patient.com',
    'EnableNodeOUs': True,
    'Template': {
        'Count': int(str(env_dict['peer_number']+1))
    },
    'Users': {
        'Count': 1
    }
}

modifiedCLI ={
    'command': '/bin/bash',
    'container_name': 'cli',
    'environment': [
        'GOPATH=/opt/gopath',
        'FABRIC_LOGGING_SPEC=INFO',
        'FABRIC_CFG_PATH=/etc/hyperledger/peercfg',
        'CORE_PEER_TLS_ENABLED=true'
    ],
    'image': 'hyperledger/fabric-tools:latest',
    'labels': {
        'service': 'hyperledger-fabric'
    },
    'networks': ['test'],
    'stdin_open': True,
    'tty': True,
    'volumes': [
        '../organizations:/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations',
        '../scripts:/opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/',
        './docker/peercfg:/etc/hyperledger/peercfg'
    ],
    'working_dir': '/opt/gopath/src/github.com/hyperledger/fabric/peer'
}


compose_data['volumes']={'peer'+str(env_dict['peer_number'])+'.patorg.patient.com' : None}
compose_data['services']={'cli':modifiedCLI}
compose_data['services']['peer'+str(env_dict['peer_number'])+'.patorg.patient.com'] =newpeer
config_data['PeerOrgs'][0] = new_peer_config

# Save the modified compose file
with open('./organizations/cryptogen/crypto-config-patorg.yaml', 'w') as file:
    yaml.dump(config_data, file)

with open('./compose/compose-test-net-2.yaml', 'w') as file:
    yaml.dump(compose_data, file)

# subprocess.run(shlex.split('./network.sh up -ca'))
subprocess.run(shlex.split('./network.sh createChannel -ca -verbose'))

env_dict['peer_number']+=1
env_dict['peer_port']+=2
env_dict['listen_port']+=1



# ------------------------------------------------------------------------------------

modified_dict = {'KeyColumn':list(env_dict.keys()),'DataColumn':list(env_dict.values())}
new_df = pd.DataFrame(modified_dict)

# Storing back to same csv file
new_df.to_csv('variable.csv')