#!/bin/bash
# createcloudaccount dsmuser dsmpass connectorName guiPort accesskey secretkey
username=$1
password=$2
accesskey=$5
secretkey=$6

# replace this with your DSM IP or FQDN
DSMURL="localhost:$4"

echo "#####Login to DSM"
tempDSSID=$(curl -k -H "Content-Type: application/json" -X POST "https://$DSMURL/rest/authentication/login/primary" -d "{"dsCredentials":{"userName":"$username","password":"$password"}}")

curl -ks -H "Content-Type: application/json" "Accept: application/json" -X POST "https://$DSMURL/rest/cloudaccounts" -d '{"createCloudAccountRequest":{"cloudAccountElement":{"accessKey":"'${accesskey}'","cloudRegion":"'amazon.cloud.region.key.10'","cloudType":"AMAZON","name":"'$3'","secretKey":"'${secretkey}'","endpoint":"'ec2.us-gov-west-1.amazonaws.com'","azureCertificate":"-"},"sessionId":"'$tempDSSID'"}}'

curl -k -X DELETE https://$DSMURL/rest/authentication/logout?sID=$tempDSSID

unset accesskey
unset secretkey
unset tempDSSID
unset username
unset password

