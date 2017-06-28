
param (
    [Parameter(Mandatory=$true)][string]$manager,
    [Parameter(Mandatory=$true)][string]$user,
    [Parameter(Mandatory=$true)][string]$awsAccessKey,
    [Parameter(Mandatory=$true)][string]$awsSecretKey,
    [Parameter(Mandatory=$true)][string]$seedRegion,
    [Parameter(Mandatory=$false)][string]$tenant
)

$passwordinput = Read-host "Password for Deep Security Manager" -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordinput))


[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}


$managerUri="https://$manager/"


$headers=@{'Content-Type'='application/json'}


try {
    $data = @{
        dsCredentials = @{
            password=$password
            userName=$user
        }
    }

    if (!$tenant) {
        $authUri = $managerUri + "rest/authentication/login/primary"
        }
    else {
        $authUri = $managerUri + "rest/authentication/login"
        $data.dsCredentials.Add("tenantName", $tenant)
        }
    $requestbody = $data | ConvertTo-Json    
    $SID=Invoke-RestMethod -Headers $headers -Method POST -Uri $authUri -Body $requestbody -SessionVariable session
} 

catch {
    echo "An error occurred during authentication. Verify username and password and try again. `nError returned was: $($_.Exception.Message)"
    exit
}

[System.Uri]$uri=$managerUri

$session.Cookies.Add((New-Object System.Net.Cookie -Property @{     
       'Name' = "sID"
       'Value' = "$SID"
       'domain' = $uri.Host
       }))

$requestUri = $managerUri + "rest/cloudaccounts/aws"

$requestdata = @{
    AddAwsAccountRequest = @{
        awsCredentials = @{
            accessKeyId=$awsAccessKey
            secretKey=$awsSecretKey
            }
        seedRegion=$seedRegion
        }
    }

$requestbody = $requestdata | ConvertTo-Json

$Global:response = Invoke-RestMethod -Headers $headers -Method POST -Uri $requestUri -WebSession $session -Body $requestbody

$response
