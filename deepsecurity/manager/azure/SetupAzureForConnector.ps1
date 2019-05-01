<#
    .SYNOPSIS
    Powershel script to setup an azure account for a cloud connector. 
    .DESCRIPTION
    This script creates an App regestration and service principal for a Trend Micro Azure cloud connector. 
    This script outputs json that works with the addAzureConnector.py script to add the connector to the DSM.
#>

#Name of the connector in Azure
$appName = "Deep Security Azure Connector"
#Password is 32 long 
Add-Type -AssemblyName System.Web
$password = [System.Web.Security.Membership]::GeneratePassword(32,0)


$psadCredential = New-Object  Microsoft.Azure.Graph.RBAC.Version1_6.ActiveDirectory.PSADPasswordCredential 
$startDate = Get-Date
$psadCredential.StartDate = $startDate
$psadCredential.EndDate = $startDate.AddYears(10)
$psadCredential.KeyId = [guid]::NewGuid()
$psadCredential.Password = $password

#If you need to login to a specific subscription otherwise just login
#$c = Login-AzureRmAccount -SubscriptionId "b0ba4069-ce0a-4f1f-c623-711faae9620b"
$c = Login-AzureRmAccount 

#Create the new application regestration
$d = New-AzureRmADApplication -DisplayName $appName -HomePage "http://www.trendmicro.com" -IdentifierUris "http://NewApplication" -PasswordCredentials $psadCredential 
#Create the new service principal
$f = New-AzureRmADServicePrincipal  -ApplicationId  $d.ApplicationId 
#Useful to debug
#$f
#Assign the new service princiapl rights to read from the Azure account
$t = New-AzureRmRoleAssignment -RoleDefinitionName "Reader" -ServicePrincipalName $d.ApplicationId
#Useful to debug
#$t


#Build the output to match what is expected in Deep Security API for createing the connector. 
$outputObject = New-Object -TypeName psobject 
#This will be the name of the connector in Deep Security. 
$outputObject | Add-Member -MemberType NoteProperty -Name name -Value $c.Context.Account.Id
$outputObject | Add-Member -MemberType NoteProperty -Name cloudType -Value "AZURE_ARM"
$outputObject | Add-Member -MemberType NoteProperty -Name subscriptionId -Value $c.Context.Subscription.SubscriptionId
$outputObject | Add-Member -MemberType NoteProperty -Name subscriptionName -Value $c.Context.Subscription.Name
$outputObject | Add-Member -MemberType NoteProperty -Name azureAdTenantId -Value $c.Context.Tenant.TenantId
$outputObject | Add-Member -MemberType NoteProperty -Name azureAdTenantName -Value $c.Context.Tenant.Directory
$outputObject | Add-Member -MemberType NoteProperty -Name azureAdApplicationId -Value $d.ApplicationId
$outputObject | Add-Member -MemberType NoteProperty -Name azureAdApplicationName -Value $appName
$outputObject | Add-Member -MemberType NoteProperty -Name azureAdApplicationPassword -Value $password

$outputObject | ConvertTo-Json
