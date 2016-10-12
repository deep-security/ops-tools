#!/bin/bash
## usage:
## ds-cfg-relay <managerUrl> <managerUsername> <agentHostname> <true||false||status>
if [[ $1 == *"help"* ]]
then
  echo -e "## usage:\n## ds-cfg-relay <managerUrl> <managerUsername> <agentHostname> <true||false||status>\n"
  echo -e "## example to enable relay on an agent:\n"
  echo -e "## ds-cfg-relay dsm.example.local:443 administrator relay.example.local true"
  echo -e "## example to show relay status for an agent in DSaaS\n"
  echo -e "## ds-cfg-relay app.deepsecurity.trendmicro.com:443 administrator relay.customer.local status CustomerTenant\n"
  exit 0
fi
command -v xml_grep >/dev/null 2>&1 || { echo >&2 "This script requires xml_grep. Please install perl-XML-Twig before proceeding."; exit 1; }

manager=$1
SID=

read -sr -p $'Password: ' password

if [[ -z $5 ]]
  then
    SID=`curl -ks -H "Content-Type: application/json" -X POST "https://${manager}/rest/authentication/login/primary" -d '{"dsCredentials":{"userName":"'${2}'","password":"'$password'"}}'`
  else
    SID=`curl -ks -H "Content-Type: application/json" -X POST "https://${manager}/rest/authentication/login" -d '{"dsCredentials":{"userName":"'${2}'","password":"'${password}'","tenantName":"'${5}'"}}'`
fi
unset Password

## get hostid
hostId=$(curl -ks -H "Content-Type: text/xml;charset=UTF-8" -H 'SOAPAction: "hostRetrieveByName"' "https://${manager}/webservice/Manager" -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager"><soapenv:Header/><soapenv:Body><urn:hostRetrieveByName><urn:hostname>'$3'</urn:hostname><urn:sID>'$SID'</urn:sID></urn:hostRetrieveByName></soapenv:Body></soapenv:Envelope>' | xml_grep ID --text_only)

echo -e "\n\nhostId is ${hostId}\n\n"

case $4 in
  true)
## turn on relay
curl -ks -H "Content-Type: text/xml;charset=UTF-8" -H 'SOAPAction: "hostSettingSet"' "https://${manager}/webservice/Manager" -d \
'<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager">'\
'<soapenv:Header/>'\
'<soapenv:Body>'\
'<urn:hostSettingSet>'\
'<urn:hostID>'$hostId'</urn:hostID>'\
'<urn:editableSettings>'\
'<urn:settingKey>CONFIGURATION_RELAYSTATE</urn:settingKey>'\
'<urn:settingUnit>NONE</urn:settingUnit>'\
'<urn:settingValue>true</urn:settingValue>'\
'</urn:editableSettings>'\
'<urn:sID>'$SID'</urn:sID>'\
'</urn:hostSettingSet>'\
'</soapenv:Body>'\
'</soapenv:Envelope>'
  ;;
  false)
## turn off relay
curl -ks -H "Content-Type: text/xml;charset=UTF-8" -H 'SOAPAction: "hostSettingSet"' "https://${manager}/webservice/Manager" -d \
'<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager">'\
'<soapenv:Header/>'\
'<soapenv:Body>'\
'<urn:hostSettingSet>'\
'<urn:hostID>'$hostId'</urn:hostID>'\
'<urn:editableSettings>'\
'<urn:settingKey>CONFIGURATION_RELAYSTATE</urn:settingKey>'\
'<urn:settingUnit>NONE</urn:settingUnit>'\
'<urn:settingValue>false</urn:settingValue>'\
'</urn:editableSettings>'\
'<urn:sID>'$SID'</urn:sID>'\
'</urn:hostSettingSet>'\
'</soapenv:Body>'\
'</soapenv:Envelope>' 
  ;;
  status)
## get relay setting value
status=$(curl -ks -H "Content-Type: text/xml;charset=UTF-8" -H 'SOAPAction: "hostSettingGet"' "https://${manager}/webservice/Manager" -d \
'<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager">'\
'<soapenv:Header/>'\
'<soapenv:Body>'\
'<urn:hostSettingGet>'\
'<urn:hostID>'$hostId'</urn:hostID>'\
'<urn:keys>CONFIGURATION_RELAYSTATE</urn:keys>'\
'<urn:sID>'$SID'</urn:sID>'\
'</urn:hostSettingGet>'\
'</soapenv:Body>'\
'</soapenv:Envelope>' | xml_grep settingValue --text_only)
echo "Relay setting is now set to ${status}. If you've just modified the setting, it may not be reflected in status until next agent heartbeat."

esac


unset SID
