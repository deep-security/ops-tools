param (
    [Parameter(Mandatory=$true)][string]$manager,
    [Parameter(Mandatory=$true)][string]$user,
    [Parameter(Mandatory=$true)][string]$policyname,
    [Parameter(Mandatory=$true,HelpMessage="enter Inherit, AIA, MIA, or Bi to set comm direction; status to query")][ValidateSet("Inherit","AIA","MIA","Bi","status")][string]$commdirection = "status",
    [Parameter(Mandatory=$false)][string]$tenant
)
$passwordinput = Read-host "Password for Deep Security Manager" -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordinput))

$cd = 0

switch ($commdirection)
    {
        Inherit {$cd=0}
        AIA {$cd=1}
        MIA {$cd=2}
        Bi {$cd=3}
    }


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

    $spt = $DSM.securityProfileRetrieveByName($policyname, $SID)
try {
    if ($commdirection -eq "status") {
        [DSSOAP.EnumEditableSettingKey[]] $settingskeyarray = @([DSSOAP.EnumEditableSettingKey]::CONFIGURATION_AGENTCOMMUNICATIONS)
        $ESSTreturn = $DSM.securityProfileSettingGet($spt.ID, $settingskeyarray, $SID)
        echo $ESSTreturn[0].settingValue
        }
    elseif ($cd -eq 0) {
        [DSSOAP.EnumEditableSettingKey[]] $settingskeyarray = @([DSSOAP.EnumEditableSettingKey]::CONFIGURATION_AGENTCOMMUNICATIONS)
        $DSM.securityProfileSettingClear($spt.ID, $settingskeyarray, $SID)
    }
    else {
        $EST = New-Object DSSOAP.EditableSettingTransport
        $EST.settingUnit = [DSSOAP.EnumEditableSettingUnit]::NONE
        $EST.settingValue = $cd
        $EST.settingKey = @([DSSOAP.EnumEditableSettingKey]::CONFIGURATION_AGENTCOMMUNICATIONS)
        [DSSOAP.EditableSettingTransport[]] $ESTArray = @($EST)
        $DSM.securityProfileSettingSet($spt.ID, $ESTArray, $SID)
        }
}
catch {
    echo "Exception occured.`nError returned from DSM was: $($_.Exception.Message)"
}
finally {
    $DSM.endSession($SID)
}
$DSM.endSession($SID)
