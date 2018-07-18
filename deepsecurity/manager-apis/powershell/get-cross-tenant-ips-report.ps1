param (
    [Parameter(Mandatory=$true)][string]$manager,
    [Parameter(Mandatory=$true)][string]$user,
    [Parameter(Mandatory=$true)][string]$filename
)

$passwordinput = Read-host "Password for Deep Security Manager" -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordinput))

function login-restTenant
{
    param( [string]$tenantName, [string]$SID )
    $signInAsTenantAuthUri = $managerUri + "authentication/signinastenant/name/" + $tenantName + "?sID=" + $Global:SID
    Invoke-RestMethod -Headers $headers -Method GET -Uri $signInAsTenantAuthUri
}

function evaluate-rules
{
    param( [string]$token, [string]$tenantname )
    $allHosts = $DSM.hostRetrieveAll($token)
    $currentHostCouneter = 0
    Write-Host "Found $($allhosts.Count) hosts in tenant $($tenantname)."

    foreach ($ht in $allHosts)
    {
        $currentHostCouneter++
        Write-Progress -Activity "Checking rules on $($AllHosts.Count) hosts in $tenantname" -status "Looking at host $($ht.name)" -percentComplete ($currentHostCouneter / $allHosts.Count)

        if ($ht.hostType -like "ESX")
        {
            continue
        }
        $hs = $DSM.hostGetStatus($ht.ID, $token)
        $RecommendedAllDetectCount  =0
        $recommendedUnassignedDetectCount = 0
        $detections = get-events $token $ht.id
        
        if ($hs.overallStatus -like 'Unmanaged*' -Or $hs.overallDpiStatus -like '*OFF*' -Or $hs.overallDpiStatus -like 'Not Activated')
            {
                $csvline = New-Object PSObject;
                $csvline | Add-Member -MemberType NoteProperty -Name TenantName -Value $tenantname
                $csvline | Add-Member -MemberType NoteProperty -Name DisplayName -Value $ht.DisplayName;
                $csvline | Add-Member -MemberType NoteProperty -Name HostName -Value $ht.name;
                $csvline | Add-Member -MemberType NoteProperty -Name OverallStatus -Value $hs.overallStatus
                #$csvline | Add-Member -MemberType NoteProperty -Name TotalAssignedRules -Value "N/A"
                $csvline | Add-Member -MemberType NoteProperty -Name TotalRecomendedRules -Value "N/A"                
                $csvline | Add-Member -MemberType NoteProperty -Name UnassignedRecommendedRules -Value "N/A"
                $csvline | Add-Member -MemberType NoteProperty -Name AssignedRulesInDetect -Value "N/A"
                $csvline | Add-Member -MemberType NoteProperty -Name AssignedRulesInPrevent -Value "N/A"
                $csvline | Add-Member -MemberType NoteProperty -Name RecomendedRulesInDetect -Value "N/A"
                $csvline | Add-Member -MemberType NoteProperty -Name RecommendedRulesInPrevent -Value "N/A"
                $csvline | Add-Member -MemberType NoteProperty -Name DetectRulesTriggered -Value "N/A"
                $csvline | Add-Member -MemberType NoteProperty -Name PreventRulesTriggered -Value "N/A"
                $csvline | Add-Member -MemberType NoteProperty -Name LastRecommendationScan -Value "N/A"
                $csvline | export-csv $filename -Append -NoTypeInformation
                continue
            }

        $recommendedUnassigned = $DSM.hostRecommendationRuleIDsRetrieve($ht.ID, 2, $true, $token)
        $recommendedAll = $DSM.hostRecommendationRuleIDsRetrieve($ht.ID, 2, $false, $token)
        foreach($rule in $recommendedUnassigned)
        {
            if ($rule.detectOnly -eq $true) {$recommendedUnassignedDetectCount++}
        }
        
        foreach($rule in $recommendedAll)
        {
            if ($rule.detectOnly -eq $true) {$RecommendedAllDetectCount++}
        }
        
        $hft = new-object DSSOAP.HostFilterTransport
        $hft.type = [DSSOAP.EnumHostFilterType]::SPECIFIC_HOST
        $hft.hostID = $ht.id
        $hdt = $DSM.hostDetailRetrieve($hft, [DSSOAP.EnumHostDetailLevel]::LOW, $token)

        $detections = get-events $token $ht.id
        $csvline = New-Object PSObject;
        $csvline | Add-Member -MemberType NoteProperty -Name TenantName -Value $tenantname
        $csvline | Add-Member -MemberType NoteProperty -Name DisplayName -Value $ht.DisplayName;
        $csvline | Add-Member -MemberType NoteProperty -Name HostName -Value $ht.name;
        $csvline | Add-Member -MemberType NoteProperty -Name OverallStatus -Value $hs.overallStatus
        #$csvline | Add-Member -MemberType NoteProperty -Name TotalAssignedRules -Value $hs.overallDpiStatus.Split(",")[2]
        $csvline | Add-Member -MemberType NoteProperty -Name TotalRecomendedRules -Value $recommendedAll.Count
        $csvline | Add-Member -MemberType NoteProperty -Name UnassignedRecommendedRules -Value $recommendedUnassigned.Count
        $csvline | Add-Member -MemberType NoteProperty -Name AssignedRulesInDetect -Value ($RecommendedAllDetectCount - $recommendedUnassignedDetectCount)
        $csvline | Add-Member -MemberType NoteProperty -Name AssignedRulesInPrevent -Value ($recommendedAll.Count - $assignedDetectCount)
        $csvline | Add-Member -MemberType NoteProperty -Name RecomendedRulesInDetect -Value $RecommendedAllDetectCount
        $csvline | Add-Member -MemberType NoteProperty -Name RecommendedRulesInPrevent -Value ($recommendedAll.Count - $recommendedDetectCount)
        $csvline | Add-Member -MemberType NoteProperty -Name DetectRulesTriggered -Value $detections[0]
        $csvline | Add-Member -MemberType NoteProperty -Name PreventRulesTriggered -Value $detections[1]
        $csvline | Add-Member -MemberType NoteProperty -Name LastRecommendationScan -Value $hdt.overallLastRecommendationScan
        $csvline | export-csv $filename -Append -NoTypeInformation
    }
}

function get-events
{
    param( [string]$token, [int]$hostid )
    $tagfilter = New-Object DSSOAP.TagFilterTransport
    $tagfilter.type = [DSSOAP.EnumTagFilterType]::ALL
    $timefilter = New-Object DSSOAP.TimeFilterTransport
    $timefilter.type = [DSSOAP.EnumTimeFilterType]::LAST_24_HOURS
    $hostfilter = New-Object DSSOAP.HostFilterTransport
    $hostfilter.type = [DSSOAP.EnumHostFilterType]::SPECIFIC_HOST
    $hostfilter.hostID = $hostid
    $idfilter = New-Object DSSOAP.IDFilterTransport2
    $detectCounter = $DSM.counterRetrieve([DSSOAP.EnumCounterFilter]::DPI_DETECT_COMPUTER_ACTIVITY, $timefilter, $hostfilter, $tagfilter, $token)
    $preventCounter = $DSM.counterRetrieve([DSSOAP.EnumCounterFilter]::DPI_PREVENT_COMPUTER_ACTIVITY, $timefilter, $hostfilter, $tagfilter, $token)
    if ($detectCounter -is [DSSOAP.CounterTransport[]])
    {
        $detectCounter[0].value
    }
    else
    {
        "N/A"
    }

    if ($preventCounter -is [DSSOAP.CounterTransport[]])
    {
        $preventCounter[0].value
    }
    else
    {
        "N/A"
    }

}

[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}
[Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
$DSMSoapService = New-WebServiceProxy -uri "https://$manager/webservice/Manager?WSDL" -Namespace "DSSOAP" -ErrorAction Stop
$DSM = New-Object DSSOAP.ManagerService

$managerUri="https://$manager/rest/"
$headers=@{'Content-Type'='application/json'}

try {
    $data = @{
        dsCredentials = @{
            password=$password
            userName=$user
            }
    }

    $authUri = $managerUri + "authentication/login/primary"

    $requestbody = $data | ConvertTo-Json    

    $Global:SID=Invoke-RestMethod -Headers $headers -Method POST -Uri $authUri -Body $requestbody
}
catch {
    echo "An error occurred during authentication. Verify username and password and try again. `nError returned was: $($_.Exception.Message)"
    exit
}

$multiTenant=$true
try {
    $methodUri = $managerUri + "tenants?sID=" + $Global:SID
    $Global:tenantListing = Invoke-RestMethod -Headers $headers -Method GET -Uri $methodUri
}

catch {
    $multiTenant=$false
    echo "Multi-tenant feature is not enabled; processing T0 only"
}

try {
    evaluate-rules $Global:SID "T0"
    if ($multiTenant -eq $true)
    {
        foreach ($tenant in $tenantListing.tenantListing.tenants)
            {
                $tenantSid = login-restTenant $tenant.name $Global:SID
                evaluate-rules $tenantSid $tenant.name
                $DSM.endSession($tenantSid)
            }
    }
}
catch {
    echo "An error occurred while processing host rules. `nError returned was; $($_.Exception.Message)"
}

finally {
    $DSM.endSession($Global:SID)
}