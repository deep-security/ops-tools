# ops-tools

A set of handy tools to make it easier to run to Deep Security.

## Manager Tools

### Bash

<dl>
<dt>config-dsRelay.sh</dt>
<dd>Query the status of, enable, or disable relay functionality on an agent</dd>
<dt>config-rehomeAwsDsManager.sh</dt>
<dd>Used by our cloud formation projects to ensure the correct cloud connector sync'd object is activated</dd>
<dt>create-iamCloudAccount.sh</dt>
<dd>Create an IAM user and associated keys, then use those keys to create the DS cloud connector</dd>
<dt>rest-cloudAccountsCreateAws.sh</dt>
<dd>Create cloud accounts for all regions</dd>
<dt>rest-cloudAccountsCreateAws.sh</dt>
<dd>Create cloud account for GovCloud</dd>
<dt>rest-tenantsCreate.sh</dt>
<dd>Create new tenant</dd>
</dl>

### Powershell  

<dl>
<dt>config-dsRelay.ps1</dt>
<dd>Query the status of, enable, or disable relay functionality on an agent</dd>
<dt>config-ipsXforwardedForRule.ps1</dt>
<dd>Create or update an IPS rule which a list of IPS to be blocked based on header added by an AWS ELB</dd>
<dt>config-plicy-agentcomm.ps1</dt>
<dd>Configure manager agent communication direction on a policy</dd>
<dt>get-allHostsSummary.ps1</dt>
<dd>Get summary of all host objects in deep security manager similar to dashboard status widget</dd>
<dt>get-amComponentVersions.ps1</dt>
<dd>Get detailed agent and am engine versions for a host object</dd>
<dt>get-computerCreatedEvents.ps1</dt>
<dd>Get all computer created system events for a given time frame</dd>
<dt>get-firewallrules.ps1</dt>
<dd>Get all firewall rules for a given host object</dd>
<dt>get-hostIpsRules.ps1</dt>
<dd>Get all ips rules assigned to a policy for each host object in the DSM</dd>
<dt>get-hostRecoAndAssignedRules.ps1</dt>
<dd>Get count of assigned and recommended rules for each host object in the DSM</dd>
<dt>get-macFromInterfaces.ps1</dt>
<dd>Get all interfaces and their mac addresses for a given host object</dd>
<dt>get-managedHostCounts.ps1</dt>
<dd>Get a simple count of all Unmanaged vs not Unmanaged hosts in the DSM</dd>
<dt>rest-authenticationLogin.ps1</dt>
<dd>Rest call to get a Security ID token for subsequent calls. SID returned may be used for SOAP or REST calls</dd>
<dt>rest-managerInfoComponents.ps1</dt>
<dd>Rest call to get list of current components available in the DSM</dd>
<dt>setup-dsSoap.ps1</dt>
<dd>Setup script to leave the caller with a current token in $SID and ManagerService instance in $DSM for use in interactive shell. Also starting authenticaiton for new scripts</dd>
</dl>  

### Scheduled Task Scripts

<dl>
<dt>EnableStrongCiphers.script</dt>
<dd>Allows Deep Security to communicate exclusively with strong ciphers</dd>
</dl>

## Agent tools

<dl>
<dt>awsAgentInstallSamples</dt>
<dd>UserData and CfnInit snippets for use in integrating Deep Security Agent deployment in AWS automation tooling</dd>
</dl>

### Bash  

<dl>
<dt>get-dsaPolicy.sh</dt>
<dd>Query the local DSA for its current policyid and policyname</dd>
<dt>install-dsa.sh</dt>
<dd>Working project 'one script to rule them all'; single bash script to download, install, and activate a deep security agent on any linux distro, arch, and version</dd>
</dl>
