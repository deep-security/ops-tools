
param (
    [Parameter(Mandatory=$true)][string]$manager,
    [Parameter(Mandatory=$true)][string]$user,
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

$timestamp = Get-Date -Format yyyyMMddhhmmss
$filename = "ipsrules$($timestamp).csv"

$hts = $DSM.hostRetrieveAll($SID);

foreach ($ht in $hts)
    {
        $hft = new-object DSSOAP.HostFilterTransport
        $hft.type = [DSSOAP.EnumHostFilterType]::SPECIFIC_HOST
        $hft.hostID = $ht.ID
        $hostdetail = $DSM.hostDetailRetrieve($hft, [DSSOAP.EnumHostDetailLevel]::HIGH, $SID);
        if ($hostdetail.overallDpiStatus -like '*OFF*' -Or $hostdetail.overallDpiStatus -like 'Not Activated')
            {
                continue
            };

        Write-Host "Checking details for hostID: $($ht.ID)"
        $hostPolicy = $DSM.securityProfileRetrieve($ht.securityProfileID, $SID)
        
        foreach ($ipsrule in $hostPolicy.DPIRuleIDs)
            {
                $csvline = New-Object PSObject;
                $rule = $DSM.DPIRuleRetrieve($ipsrule, $SID);
                $csvline | Add-Member -MemberType NoteProperty -Name DisplayName -Value $ht.DisplayName;  
                $csvline | Add-Member -MemberType NoteProperty -Name HostName -Value $ht.name;  
                $csvline | Add-Member -MemberType NoteProperty -Name IP -Value $hostdetail.lastIPUsed;
                $csvline | Add-Member -MemberType NoteProperty -Name DpiRuleId -Value $rule.identifier;
                $csvline | Add-Member -MemberType NoteProperty -Name DpiRuleCveNumbers -Value $rule.cvenumbers;
                $csvline | Add-Member -MemberType NoteProperty -Name DpiRuleDescription -Value $rule.description;
                $csvline | export-csv $filename -Append
            }

    }

$DSM.endSession($SID)
