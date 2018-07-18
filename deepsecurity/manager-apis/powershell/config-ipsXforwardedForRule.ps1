<#
 
.SYNOPSIS
PowerShell Script to create and manage a Deep Security IPS rule which can block source IP addresses from behind an ELB based on x-forwarded-for header value.
 
.DESCRIPTION
The set-xForwardedFor script creates or updates an IPS rule in Deep Security Manager which can block addresses based on the X-Forwarded-For header provided by an AWS Elastic Load Balancer.
The Username and Password supplied will be used to authenticate to the Deep Security Manager.
IPs for the block list must be placed in a directory with this script in a file called ips.txt. IPs must be added to the file one address per line.
This script requires the Web Services API to be enabled on Deep Security Manager.

.PARAMETER manager
The -manager parameter requires a hostname or IP and port in the format hostname.local:4119 or 198.51.100.10:443.
 
.PARAMETER user
The -user parameter requires a Deep Security Manager Administrator with permission to use the SOAP API.

.PARAMETER tenant
The -tenant parameter is optional and can be used to specify a tenant (other than T0).

.EXAMPLE
set-xForwardedFor.ps1 -manager manager.domain.com:443 -user MasterAdmin
This example logs into tenant 0 on the Deep Security Manager.

set-xForwardedFor.ps1 -manager manager.domain.com:443 -user tenantAdmin -tenant CustomerTenant
This example logs into tenant named Customer Tenant on the Deep Security Manager.

.LINK
http://aws.trendmicro.com
 
#>

param (
    [Parameter(Mandatory=$true)][string]$manager,
    [Parameter(Mandatory=$true)][string]$user,
    [Parameter(Mandatory=$false)][string]$tenant
)

## To use this script completely automated without user input, uncomment these lines and set appropraite values
#$manager=""
#$user=""
#$password=""

## To use this script completely automated without user input, comment out these lines
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
$ruleXML = ""

Get-Content .\ips.txt | Foreach-Object{$ruleXML += "<rule pat=`"X-Forwarded-For: $_`" cmask=`"0x3`" ctest=`"0x1`">`
drop `"Found IP from Block List in XFF Header`"`
</rule>`
"}
$xfor = $DSM.DPIRuleRetrieveByName("Block-X-Forward-List", $SID)
if ($xfor.ID -eq $null)
    {
        echo "Rule did not exist; creating new"
        $xfor = New-Object DSSOAP.DPIRuleTransport
        $xfor.name = "Block-X-Forward-List"
        $xfor.applicationTypeID = $DSM.applicationTypeRetrieveByName("Web Server Common", $SID).ID
        $xfor.eventOnPacketDrop = $true
        $xfor.eventOnPacketModify = $true
        $xfor.templateType = [DSSOAP.EnumDPIRuleTemplateType]::CUSTOM_XML
        $xfor.patternAction = [DSSOAP.EnumDPIRuleAction]::DROP_CLOSE
        $xfor.patternIf = [DSSOAP.EnumDPIRuleIf]::ANY_PATTERNS_FOUND
        $xfor.priority = [DSSOAP.EnumDPIRulePriority]::NORMAL
        $xfor.signatureAction = [DSSOAP.EnumDPIRuleAction]::DROP_CLOSE
        $xfor.severity = [DSSOAP.EnumDPIRuleSeverity]::MEDIUM
    }
$xfor.ruleXML = $ruleXML
$DSM.DPIRuleSave($xfor, $SID)
$DSM.endSession($SID)
