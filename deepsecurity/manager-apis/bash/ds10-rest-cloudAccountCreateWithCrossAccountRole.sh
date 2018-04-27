#!/bin/bash
# cloudAccountCreateWithCrossAccountRole.sh dsmuser dsmpass managerAddress guiPort roleArn externalId tenant
username=$1
password=$2
DSMURL="$3:$4"
arn="$5"
externalId="$6"
tenant=$7




echo "#####Login to DSM"
if [[ -z $tenant ]]
  then
      SID=`curl -ks -H "Content-Type: application/json" -X POST "https://${DSMURL}/rest/authentication/login/primary" -d '{"dsCredentials":{"userName":"'${username}'","password":"'${password}'"}}'`
  else
      SID=`curl -ks -H "Content-Type: application/json" -X POST "https://${DSMURL}/rest/authentication/login" -d '{"dsCredentials":{"userName":"'${username}'","password":"'${password}'","tenantName":"'${tenant}'"}}'`
fi

curl -ks --cookie "sID=${SID}" -H "Content-Type: application/json" "Accept: application/json" -X POST "https://${DSMURL}/rest/cloudaccounts/aws" -d '{"AddAwsAccountRequest":{"crossAccountRole":{"roleArn":"'${arn}'","externalId":"'${externalId}'"}}}'

curl -k -X DELETE https://$DSMURL/rest/authentication/logout?sID=${SID}

unset SID
unset username
unset password


