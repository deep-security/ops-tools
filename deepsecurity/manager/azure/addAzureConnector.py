import urllib3
import json
import certifi
import sys
import os

class DeepSecurityRestApi:
    def __init__(self, config):
        self._config = config
        self._url = "https://{0}:{1}/rest".format(self._config["hostname"], self._config["port"])
        self._http = urllib3.PoolManager(cert_reqs='CERT_NONE', ca_certs=certifi.where(), assert_hostname=False)
        self._sID = ""
        self._headers = { 'Content-Type': 'application/json',
                         'Accept': 'application/json'}

    def PostRequest (self, uri, body):
        requestURL = self._url + uri
        requestHeaers = self._headers
        if self._sID:
            requestHeaers.add( 'Cookie: sID=' + self._sID)
        r = self._http.request( 'POST',
                          requestURL,
                          body=body,
                          headers=requestHeaers)
        return json.loads(r.data.decode('utf-8'))['data']

    def GetReuqest(self, uri):
        requestURL = self._url + uri
        requestHeaers = self._headers
        if self._sID:
            requestHeaers.add('Cookie: sID=' + self._sID)
        r = self._http.request('GET',
                               requestURL,
                               headers=requestHeaers)
        return json.loads(r.data.decode('utf-8'))['data']

    def Logout(self):
        requestURL = self._url + '/authentication/logout'
        requestHeaers = self._headers

        r = self._http.request('DELETE', requestURL, fields={'sID' : self._sID},headers=requestHeaers)
        if r.status == 200:
            self._sID =""
        else:
            print("Failed to logout with error status: {0} and return {1} ".format(r.status, r.data))
        return

    def Authentiate(self, username, password, tenantName):
        requestURL = self._url + '/authentication/login'
        requestHeaers = self._headers

        if tenantName:
            AuthJson = {
                "dsCredentials": {
                    "userName": username,
                    "password": password,
                    "tenantName": tenantName
                }
            }
        else:
            AuthJson = {
                "dsCredentials": {
                    "userName": username,
                    "password": password
                }
            }
        jsoon_string = json.dumps(AuthJson)
        r = self._http.request('POST', requestURL, body=jsoon_string, headers=requestHeaers)
        if r.status == 200:
            self._sID = r.data.decode("utf-8")
        else:
            print("Failed to authenticate with error status: {0} and return {1} ".format(r.status, r.data) )
        return

    def AddAzureFromFile(self, filename):
        with open(filename) as json_file:
            data = json.load(json_file)
        requestURL = self._url + '/cloudaccounts'
        requestHeaers = self._headers
        AzureConnector = {
                "createCloudAccountRequest": {
                    "cloudAccountElement": {
                "name":  data["name"],
                "cloudType":  "AZURE_ARM",
                "subscriptionId":  data["subscriptionId"],
                "subscriptionName":  data["subscriptionName"],
                "azureAdTenantId":  data["azureAdTenantId"],
                "azureAdTenantName":  data["azureAdTenantName"],
                "azureAdApplicationId":  data["azureAdApplicationId"],
                "azureAdApplicationName":  data["azureAdApplicationName"],
                "azureAdApplicationPassword": data["azureAdApplicationPassword"]
            },
                "sessionId": self._sID
            }
        }
        jsoon_string = json.dumps(AzureConnector)
        print(jsoon_string)
        r = self._http.request('POST', requestURL, body=jsoon_string, headers=requestHeaers)
        if r.status == 200:
            self._sID = r.data
        else:
            print("Failed to authenticate with error status: {0} and return {1} ".format(r.status, r.data))

        return



if __name__ == '__main__':

    config = { "hostname" : "localhost",
               "port": "443",
               }
    if len(sys.argv) != 2:
        print("Usage: addAzureConnector.py <json account data from powershell>")
        exit(0)

    dsRest = DeepSecurityRestApi(config=config)
    dsRest.Authentiate(username= os.environ.get('username', None), password=os.environ.get('password', None), tenantName="")
    dsRest.AddAzureFromFile(sys.argv[1])
    dsRest.Logout()
