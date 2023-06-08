import pandas as pd
import os
import subprocess
import shlex
import yaml
import json


def merge_objects(obj1, obj2):
    merged_obj = obj1.copy()

    for key, value in obj2.items():
        if key in merged_obj:
            if isinstance(value, dict) and isinstance(merged_obj[key], dict):
                # Recursive merge for nested objects
                merged_obj[key] = merge_objects(merged_obj[key], value)
            elif isinstance(value, list) and isinstance(merged_obj[key], list):
                # Merge lists by adding all the values
                # merged_obj[key].extend(value)
                merged_obj[key] = list(set(merged_obj[key] + value))
            elif value != merged_obj[key]:
                # Fields with different values, add both values to a list
                merged_obj[key] = [merged_obj[key], value]
        else:
            # New field in obj2, add it to merged_obj
            merged_obj[key] = value

    return merged_obj

def merge_json_files(file1, file2, output_file):
    # Read the contents of the first JSON file
    with open(file1, 'r') as f1:
        data1 = json.load(f1)

    # Read the contents of the second JSON file
    with open(file2, 'r') as f2:
        data2 = json.load(f2)

    # Merge the two JSON objects
    merged_data = merge_objects(data1, data2)

    # Write the merged data to the output file
    with open(output_file, 'w') as outfile:
        json.dump(merged_data, outfile, indent=4)





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
        'CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock',
        'CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=fabric_test',
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
        './docker/peercfg:/etc/hyperledger/peercfg',
        '${DOCKER_SOCK}:/host/var/run/docker.sock',
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
    'depends_on' :[
        'peer${PEER_PATIENT_NUMBER}.patorg.patient.com'
    ],
    'networks': ['test'],
    'stdin_open': True,
    'tty': True,
    'volumes': [
        '../organizations:/etc/hyperledger/fabric/peer/organizations',
        '../../../DoctorNodeCreater/network/organizations:/etc/hyperledger/fabric/peer/doctorOrganization',
        '../scripts:/etc/hyperledger/fabric/peer/scripts/',
        './docker/peercfg:/etc/hyperledger/peercfg'
    ],
    'working_dir': '/etc/hyperledger/fabric/peer'
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

subprocess.run(shlex.split('./network.sh deployCC -ccn patdoccc -ccp ../Chaincode-go -ccl go -verbose'))

if str(env_dict['peer_number']) != '0':
    merge_json_files('organizations/peerOrganizations/patorg.patient.com/connection-patorg.json', 'organizations/peerOrganizations/patorg.patient.com/temp-connection-patorg.json', 'organizations/peerOrganizations/patorg.patient.com/connection-patorg.json')


env_dict['peer_number']+=1
env_dict['peer_port']+=2
env_dict['listen_port']+=1



# ------------------------------------------------------------------------------------

modified_dict = {'KeyColumn':list(env_dict.keys()),'DataColumn':list(env_dict.values())}
new_df = pd.DataFrame(modified_dict)

# Storing back to same csv file
new_df.to_csv('variable.csv')