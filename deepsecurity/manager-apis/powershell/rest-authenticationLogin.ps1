param (
    [Parameter(Mandatory=$true)][string]$manager,
    [Parameter(Mandatory=$true)][string]$user,
    [Parameter(Mandatory=$false)][string]$tenant
)

$passwordinput = Read-host "Password for Deep Security Manager" -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordinput))


[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}
[Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12

$managerUri="https://$manager/rest/"
$Global:SID
$authUri

$headers=@{'Content-Type'='application/json'}

try {
    $data = @{
        dsCredentials = @{
            password=$password
            userName=$user
            }
    }
    if (!$tenant) {
        $authUri = $managerUri + "authentication/login/primary"
        }
    else {
        $authUri = $managerUri + "authentication/login"
        $data.dsCredentials.Add("tenantName", $tenant)
        }

    
    $requestbody = $data | ConvertTo-Json    

    $Global:SID=Invoke-RestMethod -Headers $headers -Method POST -Uri $authUri -Body $requestbody
}
catch {
    echo "An error occurred during authentication. Verify username and password and try again. `nError returned was: $($_.Exception.Message)"
    exit
}



