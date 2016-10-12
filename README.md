# ops-tools
A set of handy tools to make it easier to run to Deep Security

## manager tools
-bash
config-dsRelay.sh: query the status of, enable, or disable relay functionality on an agent  
config-rehomeAwsDsManager.sh: used by our cloud formation projects to ensure the correct cloud connector sync'd object is activated  
create-iamCloudAccount.sh: create an iam user and associated keys, then use those keys to create the DS cloud connector  
rest-cloudAccountsCreateAws.sh: create cloud accounts for all regions  
rest-cloudAccountsCreateAws.sh: create cloud account for GovCloud  
rest-tenantsCreate.sh: create new tenant  

-powershell  
config-dsRelay.ps1: query the status of, enable, or disable relay functionality on an agent  
config-ipsXforwardedForRule.ps1: create or update an ips rule which a list of ips to be blocked based on header added by an AWS ELB  
config-plicy-agentcomm.ps1: configure manager agent communication direction on a policy  
get-allHostsSummary.ps1: get summary of all host objects in deep security manager similar to dashboard status widget  
get-amComponentVersions.ps1: get detailed agent and am engine versions for a host object  
get-computerCreatedEvents.ps1: get all computer created system events for a given time frame  
get-firewallrules.ps1: get all firewall rules for a given host object  
get-hostIpsRules.ps1: get all ips rules assigned to a policy for each host object in the dsm  
get-hostRecoAndAssignedRules.ps1: get count of assigned and recommended rules for each host object in the dsm  
get-macFromInterfaces.ps1: get all interfaces and their mac addresses for a given host object  
get-managedHostCounts.ps1: get a simple count of all Unmanaged vs not Unmanaged hosts in the dsm  
rest-authenticationLogin.ps1: rest call to get a Security ID token for subsequent calls. SID returned may be used for SOAP or REST calls  
rest-managerInfoComponents.ps1: rest call to get list of current components available in the DSM  
setup-dsSoap.ps1: setup script to leave the caller with a current token in $SID and ManagerService instance in $DSM for use in interactive shell. Also starting authenticaiton for new scripts  


## agent tools
-awsAgentInstallSamples  
UserData and CfnInit snippets for use in integrating Deep Security Agent deployment in AWS automation tooling  

-bash  
get-dsaPolicy.sh: query the local DSA for its current policyid and policyname  
install-dsa.sh: working project 'one script to rule them all'; single bash script to download, install, and activate a deep security agent on any linux distro, arch, and version  


