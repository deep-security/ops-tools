
# Azure Support

## Azure Connector
To help make the Azure connector easy in Deep Security you can run the SetupAzureForConnector.ps1 powershell script to setup Azure side. It will create an app registration and service princaple in Azure and then output a json secion. This json is then consumed by the python script, addAzureConnector.py, to create the connection in the DSM. 

## Example

1) Run the powershell script to create the app regestration. After a sucessful run you will get a json output.
~~~~JSON
{
    "name":  "My Azure Account",
    "cloudType":  "AZURE_ARM",
    "subscriptionId":  "24be60c9-e19a-4faf-9623-6b140a29620b",
    "subscriptionName":  "Pay-As-You-Go",
    "azureAdTenantId":  "d3e340ca-98bf-4dbf-9586-506a71f8d53c",
    "azureAdTenantName":  "My Teant",
    "azureAdApplicationId":  "164a6d85-9a55-4e19-84ba-54ec41040ac4",
    "azureAdApplicationName":  "Deep Security Azure Connector",
    "azureAdApplicationPassword":  "k7t|.-AE/Mqm3bn^2mdgFf\u003eQVm$|fz\u003eR"
}

~~~~
2) Next Send the json output to the Deep Security administrator. 
The Deep Security administrator will then put the json into a file and call the python script. Note the python script requires a username/password (not an API key) and these values are set in environment variables "username" and "password" 

~~~~bash
 python addAzureConnector.py account.json 
~~~~
3) Verify the connector syncs correclty in the DSM. 