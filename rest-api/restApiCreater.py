import subprocess
import os
import pandas as pd

df = pd.read_csv('variable.csv')

# Creating a dictionary to get all environment variable values
env_dict={}
for index in range(len(df.index)):
    env_dict[df['KeyColumn'].iloc[index]] =df['DataColumn'].iloc[index]

os.environ['PEER_PATIENT_NUMBER'] = str(env_dict['peer_number'])



