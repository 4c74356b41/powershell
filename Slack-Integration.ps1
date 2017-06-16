param (
	[Object] $WebhookData
)

function Get-SlackParameter {
	<#
	.Synopsis
	This function takes the input parameters to a Webhook call by the Slack service. The function translates the query
	string, provided by the Slack service, and returns a PowerShell HashTable of key-value pairs. Azure Automation accepts
	a $WebhookData input parameter, for Webhook invocations, and you should pass the value of the RequestBody property
	into this function's WebhookPayload parameter.
	
	.Parameter WebhookPayload
	This parameter accepts the Azure Automation-specific $WebhookData.RequestBody content, which contains
	input parameters from Slack. The function parses the query string, and returns a HashTable of key-value
	pairs, that represents the input parameters from a Webhook invocation from Slack.
	
	eg. var1=value1&var2=value2&var3=value3 
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $WebhookPayload
	)
	
	$ParamHT = @{ };
	$Params = $WebhookPayload.Split('&');
	
	foreach ($Param in $Params) {
		try {
			$Param = $Param.Split('=');
			$ParamHT.Add($Param[0], [System.Net.WebUtility]::UrlDecode($Param[1]))			
		}
		catch {
			Write-Warning -Message ('Possible null parameter value for {0}' -f $Param[0]);
		}
	}
	
	Write-Output -InputObject $ParamHT;
}

$SlackParams = Get-SlackParameter -WebhookPayload $WebhookData.RequestBody;
function Send-SlackMessage {
	<#
	.Synopsis
	This function sens a message to a Slack channel.
	
	.Description
	This function sens a message to a Slack channel. There are several parameters that enable you to customize
	the message that is sent to the channel. For example, you can target the message to a different channel than
	the Slack incoming webhook's default channel. You can also target a specific user with a message. You can also
	customize the emoji and the username that the message comes from.
	
	For more information about incoming webhooks in Slack, check out this URL: https://api.slack.com/incoming-webhooks
	
	.Parameter Message
	The -Message parameter specifies the text of the message that will be sent to the Slack channel.
	
	.Parameter Channel
	The name of the Slack channel that the message should be sent to.
	
	- You can specify a channel, using the syntax: #<channelName>
	- You can target the message at a specific user, using the syntax: @<username>
	
	.Parameter $Emoji
	The emoji that should be displayed for the Slack message. There is an emoji cheat sheet available here:
	http://www.emoji-cheat-sheet.com/
	
	.Parameter Username
	The username that the Slack message will come from. You can customize this with any string value.
	
	.Links
	https://api.slack.com/incoming-webhooks - More information about Slack incoming webhooks
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $Message
	  , [Parameter(Mandatory = $false)]
	    [string] $Channel = ''
	  , [Parameter(Mandatory = $false)]
	    [string] $Emoji = ''
	  , [Parameter(Mandatory = $false)]
	    [string] $Username = 'Azure Automation'
	)
	
	### Build the payload for the REST method call
	$RestBody = @{ 
		text = $Message;
		username = $Username;
		icon_emoji = $Emoji;
		}
	
	### Build the command invocation parameters for Splatting on Invoke-RestMethod
	$RestCall = @{
		Body = (ConvertTo-Json -InputObject $RestBody);
		Uri = Get-AutomationVariable -Name SlackIncomingWebhook;
		ContentType = 'application/json';
		Method = 'POST';		
	}
	
	### Invoke the REST method call to the Slack service's webhook.
	Invoke-RestMethod @RestCall;
	
	Write-Verbose -Message 'Sent message to Slack service';
}
Send-SlackMessage -Message 'Wroom!';
$null = Add-AzureRmAccount -Credential (Get-AutomationPSCredential -Name AzureAdmin)

if ($SlackParams.Text -like 'go*') {

    #¡ready
    Send-SlackMessage -Message 'Preparing Crazy Stuff';
    $SlackTextArr = $SlackParams.Text.Split(' ');
    $resourceGroupName = $SlackTextArr[1] 
    $location = $SlackTextArr[2]
    $vaultName = $SlackTextArr[3]
    $pwd = $SlackTextArr[4]

    #set!
    New-AzureRmResourceGroup –Name $resourceGroupName –Location $location
    Send-SlackMessage -Message 'Created RG'
    New-AzureRmKeyVault -VaultName $vaultName -ResourceGroupName $resourceGroupName -Location $location
    Send-SlackMessage -Message 'Created Vault'
    Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultname -ObjectId '0a1e3ccc-1235-4342-96e4-ae8fd8090ad0' -PermissionsToSecrets get,set
    Set-AzureRmKeyVaultAccessPolicy -EnabledForTemplateDeployment -VaultName $vaultName
    Set-AzureKeyVaultSecret -VaultName $vaultName -Name 'administratorLoginPassword' -SecretValue (ConvertTo-SecureString $pwd -AsPlainText -Force)
    Send-SlackMessage -Message 'Prepared Vault'

    #¡go!
    $parameters = @{
        "Name" = "bbbb-is-the-word"
        "Mode" = "Incremental"
        "ResourceGroupName" = "$resourceGroupName"
        "TemplateUri"="https://raw.githubusercontent.com/4c74356b41/bbbb-is-the-word/master/ARM/parent.json"
        "SITENAME-PRIMARY"="$resourceGroupName-1s-the-word"
        "SITENAME-SECONDARY"="$resourceGroupName-1s-the-wordd"
        "SITENAME-FUNCTIONS"="$resourceGroupName-funct1ons"
        "HOSTINGPLAN-PRIMARY"="Plan-a"
        "HOSTINGPLAN-SECONDARY"="Plan-b"
        "SKU"="F1"
        "ADMINISTRATORLOGIN"="dba"
        "VAULTNAME"="$vaultName"
        "SECRETNAME"="administratorLoginPassword"
        "DATABASENAME"="database"
        "SERVERNAME"="$resourceGroupName-sq1-pr1"
        "SERVERREPLICANAME"="$resourceGroupName-sq1-rep1"
        "STORAGEACCOUNTSTUB"= $resourceGroupName
    }
    Send-SlackMessage -Message 'Starting Crazy Stuff';
	try {
		$job = New-AzureRmResourceGroupDeployment @parameters
	}
	catch {
		Send-SlackMessage -Message ' >>> ### !Failed! ### <<<'
        Send-SlackMessage -Message (ConvertTo-Json -InputObject $error)
	}
 
    Send-SlackMessage -Message (ConvertTo-Json -InputObject $job.outputs.values)
	return;
}

if ($SlackParams.Text -like 'flip*') {
    Send-SlackMessage -Message 'Flipping'
    $SlackTextArr = $SlackParams.Text.Split(' ');
    $data = @{
			AzureResourceGroup = $SlackTextArr[1];
			Tag = $SlackTextArr[2];
			Shutdown = $SlackTextArr[3];	
		}

    $job = Start-AzureRmAutomationRunbook –AutomationAccountName "AzureRmAccount" –Name "Shutdown-Start-VMs-By-Resource-Group" -ResourceGroupName "AzureRm" –Parameters $data -wait
    foreach ($result in $job) {Send-SlackMessage -Message $result}
	return;
}

if ($SlackParams.Text -like 'test*') {
    Send-SlackMessage -Message 'Flipping Testo'
    $SlackTextArr = $SlackParams.Text.Split(' ');
    $data = @{
			AzureResourceGroup = $SlackTextArr[1];
			Tag = $SlackTextArr[2];
			Shutdown = $SlackTextArr[3];	
		}

    $job = Start-AzureRmAutomationRunbook –AutomationAccountName "AzureRmAccount" –Name "sample" -ResourceGroupName "AzureRm" –Parameters $data -wait
    foreach ($result in $job) {Send-SlackMessage -Message $result}
	return;
}

if ($SlackParams.Text -eq 'arml') {
	Write-Verbose -Message 'Listing Microsoft Azure Resource Manager (ARM) Resource Groups';
	Send-SlackMessage -Message ((Get-AzureRmResourceGroup).ResourceGroupName -join "`n");
	return;
}

if ($SlackParams.Text -like 'armd*') {
	try {
		$ResourceGroupName = $SlackParams.Text.Split(' ')[1];
		Write-Verbose -Message ('Deleting ARM Resource Group named {0}' -f $ResourceGroupName);
		Remove-AzureRmResourceGroup -Name $ResourceGroupName -Force -ErrorAction Stop;
		Send-SlackMessage -Message ('Azure Automation successfully deleted the ARM Resource Group named {0}' -f $ResourceGroupName)
	}
	catch {
		throw ('Error occurred while deleting ARM Resource Group {0}: {1}' -f $ResourceGroupName, $PSItem.Exception.Message);
	}
	return;
}

if ($SlackParams.Text -like 'armn*') {
	try {
		$SlackTextArr = $SlackParams.Text.Split(' ');
		$ResourceGroup = @{
			Name = $SlackTextArr[1];
			Location = $SlackTextArr[2];
			Force = $true;	
		}
		
		Write-Verbose -Message ('Creating ARM Resource Group named {0} in the {1} region.' -f $ResourceGroup.Name, $ResourceGroup.Location);
		New-AzureRmResourceGroup @ResourceGroup -ErrorAction Stop;
		Send-SlackMessage -Message ('Azure Automation successfully create the ARM Resource Group named {0} in region {1}' -f $ResourceGroup.Name, $ResourceGroup.Location)
	}
	catch {
		throw ('Error occurred while creating ARM Resource Group {0}: {1}' -f $ResourceGroup.Name, $PSItem.Exception.Message);
	}
	return;
}

Send-SlackMessage -Message ('No Slack command found in Azure Automation Runbook: {0}' -f $SlackParams.Text.Split(' ')[0]);
