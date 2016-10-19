#!/bin/bash
# cloudAccountGet.sh dsmuser dsmpass manager address guiPort tenant
username=$1
password=$2
tenant=$5

# replace this with your DSM IP or FQDN
DSMURL="$3:$4"


echo "#####Login to DSM"
if [[ -z $tenant ]]
  then
      SID=`curl -ks -H "Content-Type: application/json" -X POST "https://${DSMURL}/rest/authentication/login/primary" -d '{"dsCredentials":{"userName":"'${username}'","password":"'${password}'"}}'`
  else
      SID=`curl -ks -H "Content-Type: application/json" -X POST "https://${DSMURL}/rest/authentication/login" -d '{"dsCredentials":{"userName":"'${username}'","password":"'${password}'","tenantName":"'${tenant}'"}}'`
fi



curl -ks -H "Content-Type: application/json" "Accept: application/json" -X Get "https://${DSMURL}/rest/cloudaccounts?sID=$SID"

curl -k -X DELETE https://$DSMURL/rest/authentication/logout?sID=$tempDSSID

unset accesskey
unset secretkey
unset tempDSSID
unset username
unset password


