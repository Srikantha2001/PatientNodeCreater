package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// Chaincode structure
type PatientDataChaincode struct {
	contractapi.Contract
}

// Patient data structure
type PatientData struct {
	BloodPressure string     `json:"BloodPressure"`
	HeartRate     string    `json:"HeartRate"`
	PatientID     string    `json:"patientID"`
	Timestamp     time.Time `json:"ts"`
}

// Function to add patient 
func (p *PatientDataChaincode) StorePatientData(ctx contractapi.TransactionContextInterface, patientID string, bp string, heartrate string) error {

	// Create a new patient data object
	patientData := PatientData{
		PatientID:     patientID,
		BloodPressure: bp,
		HeartRate:     heartrate,
		Timestamp:     time.Now(),
	}

	patientDataJSON, err := json.Marshal(patientData)
	if err != nil {
		return fmt.Errorf("failed to marshal patient data: %v", err)
	}

	err = ctx.GetStub().PutState(patientID, patientDataJSON)
	if err != nil {
		return fmt.Errorf("failed to store patient data: %v", err)
	}

	return nil
}


func (d *PatientDataChaincode) GetPatientsData(ctx contractapi.TransactionContextInterface) ([]*PatientData, error) {
	// range query with empty string for startKey and endKey does an
	// open-ended query of all assets in the chaincode namespace.
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var patientsList []*PatientData
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var currentPatient PatientData
		err = json.Unmarshal(queryResponse.Value, &currentPatient)
		if err != nil {
			return nil, err
		}
		patientsList = append(patientsList, &currentPatient)
	}

	return patientsList, nil
}

// Main function
func main() {

	// Create a new chaincode object
	chaincode, err := contractapi.NewChaincode(&PatientDataChaincode{})
	if err != nil {
		fmt.Printf("Error creating patient data chaincode: %s", err.Error())
		return
	}

	// Start the chaincode
	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting patient data chaincode: %s", err.Error())
	}
}
