<#
 
.SYNOPSIS
PowerShell Script to setup objects for remote control of Deep Security Manager via SOAP API.
 
.DESCRIPTION
The ds-api script configures a Manager object for interfacing with the Deep Security Manager SOAP API. It will leave a DSSOAP.ManagerService() Object $DSM and the ManagerSerivce Namespace will be accessible as [DSSOAP].
The Username and Password supplied will be used to authenticate to the Deep Security manager and store a token in $SID.
Log out of the session when finished with $DSM.EndSession($SID).
See the WebService SDK for more information. This script requires the Web Services API to be enabled on Deep Security Manager.

.PARAMETER manager
The -manager parameter requires a hostname or IP and port in the format hostname.local:4119 or 198.51.100.10:443.
 
.PARAMETER user
The -user parameter requires a Deep Security Manager Administrator with permission to use the SOAP API.

.PARAMETER tenant
The -tenant parameter is optional and can be used to specify a tenant (other than T0) for relay operations.

.EXAMPLE
ds-api.ps1 -manager manager.domain.com:443 -user MasterAdmin
This example logs into tenant 0 on the Deep Security Manager.

ds-api.ps1 -manager manager.domain.com:443 -user tenantAdmin -tenant CustomerTenant
This example logs into tenant named Customer Tenant on the Deep Security Manager.

.LINK
http://aws.trendmicro.com
 
#>

param (
    [Parameter(Mandatory=$true)][string]$manager,
    [Parameter(Mandatory=$true)][string]$user,
    [Parameter(Mandatory=$true)][string]$computer,
    [Parameter(Mandatory=$false)][string]$tenant
)

$passwordinput = Read-host "Password for Deep Security Manager" -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordinput))

[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}
[Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
$Global:DSMSoapService = New-WebServiceProxy -uri "https://$manager/webservice/Manager?WSDL" -Namespace "DSSOAP" -ErrorAction Stop
$Global:DSM = New-Object DSSOAP.ManagerService
$Global:SID
try {
    if (!$tenant) {
        $Global:SID = $DSM.authenticate($user, $password)
        }
    else {
        $Global:SID = $DSM.authenticateTenant($tenant, $user, $password)
        }
}
catch {
    echo "An error occurred during authentication. Verify username and password and try again. `nError returned was: $($_.Exception.Message)"
    exit
}


$HT = $DSM.hostRetrieveByName($computer, $Global:SID)

$Policy = $DSM.securityProfileRetrieve($HT.securityProfileID, $Global:SID)

foreach ($ruleId in $Policy.firewallRuleIDs)
    { 
        $rule = $DSM.firewallRuleRetrieve($ruleId, $Global:SID)
        Echo "-------------------------------------------------------------------------------------"
        Echo "DestIP " + $rule.destinationId
        Echo "DestPorts " + $rule.destinationPorts
        Echo "SourceIP " + $rule.sourceIP


    }