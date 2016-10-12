<#
 
.SYNOPSIS
PowerShell Script to setup objects for remote control of Deep Security Manager via SOAP API.

.LINK
http://aws.trendmicro.com
 
#>

param (
    [Parameter(Mandatory=$true)][string]$manager,
    [Parameter(Mandatory=$true)][string]$user,
    [Parameter(Mandatory=$true)][string]$hostname,
    [Parameter(Mandatory=$false)][string]$tenant
)

$passwordinput = Read-host "Password for Deep Security Manager" -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordinput))

[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}
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


$hdt = $DSM.hostDetailRetrieveByName($hostname, [DSSOAP.EnumHostDetailLevel]::HIGH, $SID)
echo "-------------------------------------------------------------------------------------"
echo "AgentVersion: " + $hdt.overallVersion
echo "Classic Pattern Version: " + $hdt.antiMalwareClassicPatternVersion
echo "Engine Version " + $hdt.antiMalwareEngineVersion
echo "IntelliTrap Version " + $hdt.antiMalwareIntelliTrapExceptionVersion
echo "SmartScan Pattern Version: " + $hdt.antiMalwareSmartScanPatternVersion
echo "Spyware Pattern Version: " + $hdt.antiMalwareSpywarePatternVersion

$DSM.endSession($SID)
