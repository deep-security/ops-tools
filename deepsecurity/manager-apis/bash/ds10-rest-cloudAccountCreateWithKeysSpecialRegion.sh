#!/bin/bash
# cloudAccountCreateWithKeysSpecialRegion.sh dsmuser dsmpass manager_address guiPort awsAccessKey awsSecretKey seedRegion tenant
username=$1
password=$2
tenant=$8
accesskey=$5
secretkey=$6
seedregion=$7

# replace this with your DSM IP or FQDN
DSMURL="$3:$4"



echo "#####Login to DSM"
if [[ -z $tenant ]]
  then
      SID=`curl -ks -H "Content-Type: application/json" -X POST "https://${DSMURL}/rest/authentication/login/primary" -d '{"dsCredentials":{"userName":"'${username}'","password":"'${password}'"}}'`
  else
      SID=`curl -ks -H "Content-Type: application/json" -X POST "https://${DSMURL}/rest/authentication/login" -d '{"dsCredentials":{"userName":"'${username}'","password":"'${password}'","tenantName":"'${tenant}'"}}'`
fi

echo "#####Create connector"
curl -ks --cookie "sID=${SID}" -H "Content-Type: application/json" "Accept: application/json" -X POST "https://${DSMURL}/rest/cloudaccounts/aws" -d '{"AddAwsAccountRequest":{"awsCredentials":{"accessKeyId":"'${accesskey}'","secretKey":"'${secretkey}'"},"seedRegion":"'${seedregion}'"}}'

echo -e "\n#####Log out"
curl -k -X DELETE https://$DSMURL/rest/authentication/logout?sID=${SID}

unset SID
unset username
unset password


