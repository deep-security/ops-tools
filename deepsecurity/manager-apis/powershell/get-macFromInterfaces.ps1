param (
    [Parameter(Mandatory=$true)][string]$manager,
    [Parameter(Mandatory=$true)][string]$user,
    [Parameter(Mandatory=$true)][string]$hostname,
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

$hostdetails = $DSM.hostDetailRetrieveByName($hostname, [DSSOAP.EnumHostDetailLevel]::HIGH, $SID);
$hostdetail = $hostdetails[0]
Write-Host "Enumerating Interfaces via HostInterfaceTransport Objects in array HostDetailTransport.hostInterfaces:`n"
$hostdetail.hostInterfaces
Write-Host "Enumerating MAC Address on each HostInterfaceTransport:`n"
foreach ($hostinterface in $hostdetail.hostInterfaces)
{
    Write-Host "$($hostdetail.name)`t$($hostinterface.name)`t$($hostinterface.mac)"
}
$DSM.endSession($SID)