#!/bin/bash
# createcloudaccount dsmuser dsmpass connectorName guiPort accesskey secretkey
username=$1
password=$2
accesskey=$5
secretkey=$6

# replace this with your DSM IP or FQDN
DSMURL="localhost:$4"

# Remove regions you don't want from this list
REGIONS=(useast1 uswest1 uswest2 euwest1 apsoutheast1 apsoutheast2 apnortheast1 saeast1 eucentral1 apnortheast2)

# map aws regions to dsm region keys
useast1=amazon.cloud.region.key.1
uswest2=amazon.cloud.region.key.2
uswest1=amazon.cloud.region.key.3
euwest1=amazon.cloud.region.key.4
apsoutheast1=amazon.cloud.region.key.5
apnortheast1=amazon.cloud.region.key.6
saeast1=amazon.cloud.region.key.7
apsoutheast2=amazon.cloud.region.key.8
eucentral1=amazon.cloud.region.key.9
apnortheast2=amazon.cloud.region.key.12

# map aws regions to ec2 endpoints
useast1ep=ec2.us-east-1.amazonaws.com
uswest2ep=ec2.us-west-2.amazonaws.com
uswest1ep=ec2.us-west-1.amazonaws.com
euwest1ep=ec2.eu-west-1.amazonaws.com
apsoutheast1ep=ec2.ap-southeast-1.amazonaws.com
apnortheast1ep=ec2.ap-northeast-1.amazonaws.com
saeast1ep=ec2.sa-east-1.amazonaws.com
apsoutheast2ep=ec2.ap-southeast-2.amazonaws.com
eucentral1ep=ec2.eu-central-1.amazonaws.com
apnortheast2ep=ec2.ap-northeast-2.amazonaws.com


echo "#####Login to DSM"
tempDSSID=$(curl -k -H "Content-Type: application/json" -X POST "https://$DSMURL/rest/authentication/login/primary" -d "{"dsCredentials":{"userName":"$username","password":"$password"}}")

echo "#####Looping through regions to create connectors"
for region in "${REGIONS[@]}"
do
	endpoint="${region}ep"
	echo "##### creating connector for $region region with endpoint ${!endpoint}"
	curl -ks -H "Content-Type: application/json" "Accept: application/json" -X POST "https://$DSMURL/rest/cloudaccounts" -d '{"createCloudAccountRequest":{"cloudAccountElement":{"accessKey":"'${accesskey}'","cloudRegion":"'${!region}'","cloudType":"AMAZON","name":"'$3'","secretKey":"'${secretkey}'","endpoint":"'${!endpoint}'","azureCertificate":"-"},"sessionId":"'$tempDSSID'"}}'
done

curl -k -X DELETE https://$DSMURL/rest/authentication/logout?sID=$tempDSSID

unset accesskey
unset secretkey
unset tempDSSID
unset username
unset password


