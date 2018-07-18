<#
 
.SYNOPSIS
PowerShell Script to enable, disable, or query status of a Deep Security Relay.
 
.DESCRIPTION
The config-dsrelay script can enable, disable, or query the status of a relay enabled agent activated against a Deep Security Manager. It requires the Web Services API to be enabled on Deep Security Manager.

.PARAMETER relaystate
To enable a relay, set -relaystate true.
To disable a relay, set -relaystate false.
To discover the status of a relay, set -relaystate status.
If no value is supplied, status will be used.

.PARAMETER hostname
The -hostname parameter requires the DisplayName of a computer object in Deep Security Manager which has an activated Deep Security Agent. Hostnames are case sensitive and must appear as they do in Deep Security Manager console.

.PARAMETER manager
The -manager parameter requires a hostname or IP and port in the format hostname.local:4119 or 198.51.100.10:443.
 
.PARAMETER user
The -user parameter requires a Deep Security Manager Administrator with permission to use the SOAP API.

.PARAMETER tenant
The -tenant parameter is optional and can be used to specify a tenant (other than T0) for relay operations.


.EXAMPLE
config-dsrelay.ps1 -manager manager.domain.local:4119 -user admin -hostname relay.domain.local -relaystate status
This example gets the status of enabled relay for a host with DisplayName relay.domain.local.

config-dsrelay.ps1 -manager manager.domain.com:443 -user tenantAdmin -hostname 198.51.100.100 -relaystate true -tenant CustomerTenant
This example enables the relay on an agent with DisplayName 198.51.100.100 in tenant named CustomerTenant.
 
.LINK
http://aws.trendmicro.com
 
#>


param (
    [Parameter(Mandatory=$true)][string]$manager,
    [Parameter(Mandatory=$true)][string]$user,
    [Parameter(Mandatory=$true)][string]$hostname,
    [ValidateSet("true","false","status")][string]$relaystate = "status",
    [Parameter(Mandatory=$false)][string]$tenant
)
$passwordinput = Read-host "Password for Deep Security Manager" -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordinput))


[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}
[Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
$DSMSoapService = New-WebServiceProxy -uri "https://$manager/webservice/Manager?WSDL" -Namespace "DSSOAP" -ErrorAction Stop
$DSM = New-Object DSSOAP.ManagerService
$SID
try {
    if (!$tenant) {
        $SID = $DSM.authenticate($user, $password)
        }
    else {
        $SID = $DSM.authenticateTenant($tenant, $user, $password)
        }
}
catch {
    echo "An error occurred during authentication. Verify username and password and try again. `nError returned was: $($_.Exception.Message)"
    exit
}

    $HT = $DSM.hostRetrieveByName($hostname,$SID)
try {
    if ($relaystate -eq "status") {
        [DSSOAP.EnumEditableSettingKey[]] $settingskeyarray = @([DSSOAP.EnumEditableSettingKey]::CONFIGURATION_RELAYSTATE)
        $ESSTreturn = $DSM.hostSettingGet($HT.ID, $settingskeyarray, $SID)
        echo $ESSTreturn[0].settingValue
        }
    else {
        $EST = New-Object DSSOAP.EditableSettingTransport
        $EST.settingUnit = [DSSOAP.EnumEditableSettingUnit]::NONE
        $EST.settingValue = $relaystate
        $EST.settingKey = @([DSSOAP.EnumEditableSettingKey]::CONFIGURATION_RELAYSTATE)
        [DSSOAP.EditableSettingTransport[]] $ESTArray = @($EST)
        $DSM.hostSettingSet($HT.ID, $ESTArray, $SID)
        }
}
catch {
    echo "Hostname $($hostname) was not found. Note that hostnames are case sensitive. `nError returned from DSM was: $($_.Exception.Message)"
}
$DSMSoapService.endSession($SID)

