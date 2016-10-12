##reactivate-manager <username> <password> <console-port>
dnsHostNamesOn=
## get a token
SID=`curl -k -H "Content-Type: application/json" -X POST "https://localhost:$3/rest/authentication/login/primary" -d '{"dsCredentials":{"userName":"'$1'","password":"'$2'"}}'`

## get public hostname from metadata
public_hostname=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
echo -e "public hostname returned from meta-data endpoint was \"$public_hostname\"\n" > mgract.log

if [ -z $public_hostname ]
  then
    dnsHostnamesOn=false
    echo -e "dnsHostnamesOn=false\n" >> mgract.log
  else
    dnsHostnamesOn=true
    echo -e "dnsHostnamesOn=true\n" >> mgract.log
fi

## delete host object matching local-hostname metadata
curl -k -H "Content-Type: text/xml;charset=UTF-8" -H 'SOAPAction: "hostdelete"' "https://localhost:$3/webservice/Manager" -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager"><soapenv:Header/><soapenv:Body><urn:hostDelete><urn:ids>'$(curl -ks -H "Content-Type: text/xml;charset=UTF-8" -H 'SOAPAction: "hostRetrieveByName"' "https://localhost:$3/webservice/Manager" -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager"><soapenv:Header/><soapenv:Body><urn:hostRetrieveByName><urn:hostname>'$(curl http://169.254.169.254/latest/meta-data/local-hostname)'</urn:hostname><urn:sID>'$SID'</urn:sID></urn:hostRetrieveByName></soapenv:Body></soapenv:Envelope>' | xml_grep ID --text_only)'</urn:ids><urn:sID>'$SID'</urn:sID></urn:hostDelete></soapenv:Body></soapenv:Envelope>'>>mgract.log
echo -e "\n" >> mgract.log
## delete host object matching local hostname from hostname command just to be thorough
curl -k -H "Content-Type: text/xml;charset=UTF-8" -H 'SOAPAction: "hostdelete"' "https://localhost:$3/webservice/Manager" -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager"><soapenv:Header/><soapenv:Body><urn:hostDelete><urn:ids>'$(curl -ks -H "Content-Type: text/xml;charset=UTF-8" -H 'SOAPAction: "hostRetrieveByName"' "https://localhost:$3/webservice/Manager" -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager"><soapenv:Header/><soapenv:Body><urn:hostRetrieveByName><urn:hostname>'${hostname}'</urn:hostname><urn:sID>'$SID'</urn:sID></urn:hostRetrieveByName></soapenv:Body></soapenv:Envelope>' | xml_grep ID --text_only)'</urn:ids><urn:sID>'$SID'</urn:sID></urn:hostDelete></soapenv:Body></soapenv:Envelope>'>>mgract.log
echo -e "\n" >> mgract.log
## delete host object matching local hostname from hostname command just to be thorough
curl -k -H "Content-Type: text/xml;charset=UTF-8" -H 'SOAPAction: "hostdelete"' "https://localhost:$3/webservice/Manager" -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager"><soapenv:Header/><soapenv:Body><urn:hostDelete><urn:ids>'$(curl -ks -H "Content-Type: text/xml;charset=UTF-8" -H 'SOAPAction: "hostRetrieveByName"' "https://localhost:$3/webservice/Manager" -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager"><soapenv:Header/><soapenv:Body><urn:hostRetrieveByName><urn:hostname>'$(curl http://169.254.169.254/latest/meta-data/local-ipv4)'</urn:hostname><urn:sID>'$SID'</urn:sID></urn:hostRetrieveByName></soapenv:Body></soapenv:Envelope>' | xml_grep ID --text_only)'</urn:ids><urn:sID>'$SID'</urn:sID></urn:hostDelete></soapenv:Body></soapenv:Envelope>'>>mgract.log
echo -e "\n" >> mgract.log
## get Deep Security Manager policyId
policyid=$(curl -ks -H "Content-Type: text/xml;charset=UTF-8" -H 'SOAPAction: "securityProfileRetrieveByName"' "https://localhost:$3/webservice/Manager" -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager"><soapenv:Header/><soapenv:Body><urn:securityProfileRetrieveByName><urn:name>Deep Security Manager</urn:name><urn:sID>'$SID'</urn:sID></urn:securityProfileRetrieveByName></soapenv:Body></soapenv:Envelope>' | xml_grep ID --text_only)

echo -e "policyid for Deep Security Manager Policy is $policyid\n" >> mgract.log

## If the Manager node is launched into a VPC with dns names turned off, we'll need to use AIA to get the Manager nodes activated
case $dnsHostnamesOn in    
  false)
    echo -e "public hostname returned from meta-data endpoint was zero length; using AIA\n" >> mgract.log

## Set Communication Direction to Agent Initated on Deep Security Manager Policy
    curl -ks -H "Content-Type: text/xml;charset=UTF-8" -H 'SOAPAction: "securityProfileSettingGet"' "https://localhost:$3/webservice/Manager" -d \
'<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager">'\
'<soapenv:Header/>'\
'<soapenv:Body>'\
'<urn:securityProfileSettingSet>'\
'<urn:securityProfileID>'${policyid}'</urn:securityProfileID>'\
'<urn:editableSettings>'\
'<urn:settingKey>CONFIGURATION_AGENTCOMMUNICATIONS</urn:settingKey>'\
'<urn:settingUnit>NONE</urn:settingUnit>'\
'<urn:settingValue>1</urn:settingValue>'\
'</urn:editableSettings>'\
'<urn:sID>'${SID}'</urn:sID>'\
'</urn:securityProfileSettingSet>'\
'</soapenv:Body>'\
'</soapenv:Envelope>'

## AIA for manager node
    /opt/ds_agent/dsa_control -r
    /opt/ds_agent/dsa_control -a dsm://localhost:4120/ "policyid:${policyid}"
## get hostid for this manager
    publicip_hostId=$(curl -ks -H "Content-Type: text/xml;charset=UTF-8" -H 'SOAPAction: "hostRetrieveByName"' "https://localhost:$3/webservice/Manager" -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager"><soapenv:Header/><soapenv:Body><urn:hostRetrieveByName><urn:hostname>'$(curl http://169.254.169.254/latest/meta-data/public-ipv4)'</urn:hostname><urn:sID>'$SID'</urn:sID></urn:hostRetrieveByName></soapenv:Body></soapenv:Envelope>' | xml_grep ID --text_only)
## enable relay for this agent
curl -k -v -H "Content-Type: text/xml;charset=UTF-8" -H 'SOAPAction: "hostSettingSet"' "https://localhost:$3/webservice/Manager" -d \
'<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager">'\
'<soapenv:Header/>'\
'<soapenv:Body>'\
'<urn:hostSettingSet>'\
'<urn:hostID>'$publicip_hostId'</urn:hostID>'\
'<urn:editableSettings>'\
'<urn:settingKey>CONFIGURATION_RELAYSTATE</urn:settingKey>'\
'<urn:settingUnit>NONE</urn:settingUnit>'\
'<urn:settingValue>true</urn:settingValue>'\
'</urn:editableSettings>'\
'<urn:sID>'${SID}'</urn:sID>'\
'</urn:hostSettingSet>'\
'</soapenv:Body>'\
'</soapenv:Envelope>'

    ;;
  true)
    echo -e "public hostname returned from meta-data endpoint was non-zero length; using MIA\n" >> mgract.log
## get hostId of object matcihng public-hostname metadata
    public_hostId=$(curl -ks -H "Content-Type: text/xml;charset=UTF-8" -H 'SOAPAction: "hostRetrieveByName"' "https://localhost:$3/webservice/Manager" -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager"><soapenv:Header/><soapenv:Body><urn:hostRetrieveByName><urn:hostname>'$public_hostname'</urn:hostname><urn:sID>'$SID'</urn:sID></urn:hostRetrieveByName></soapenv:Body></soapenv:Envelope>' | xml_grep ID --text_only)
    echo -e "public host Id returned from manager was $public_hostId\n" >> mgract.log
## activate that hostId
    curl -k -H "Content-Type: text/xml;charset=UTF-8" -H 'SOAPAction: "hostAgentActivate"' "https://localhost:$3/webservice/Manager" -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager"><soapenv:Header/><soapenv:Body><urn:hostAgentActivate><urn:ids>'$public_hostId'</urn:ids><urn:sID>'$SID'</urn:sID></urn:hostAgentActivate></soapenv:Body></soapenv:Envelope>'>>mgract.log
    echo -e "\n" >> mgract.log
## assign Deep Security Manager Policy to that hostId
    curl -k -H "Content-Type: text/xml;charset=UTF-8" -H 'SOAPAction: "securityProfileAssignToHost"' "https://localhost:$3/webservice/Manager" -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Manager"><soapenv:Header/><soapenv:Body><urn:securityProfileAssignToHost><urn:securityProfileID>'$policyid'</urn:securityProfileID><urn:hostIDs>'$public_hostId'</urn:hostIDs><urn:sID>'$SID'</urn:sID></urn:securityProfileAssignToHost></soapenv:Body></soapenv:Envelope>'>>mgract.log
esac

## log out
curl -k -X DELETE https://localhost:$3/rest/authentication/logout?sID="$SID"
exit 0
