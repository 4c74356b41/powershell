function contribute-me {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [validateset('Article', 'Blog Site Posts', 'Book (Author)', 'Book (Co-Author)', 'Sample Project/Tools', 'Sample Code', 'Conference (booth presenter)', 'Conference (organizer)', 'Forum Moderator', 'Forum Participation (3rd Party forums)', 'Forum Participation (Microsoft Forums)', 'Mentorship', 'Open Source Project(s)', 'Other', 'Product Group Feedback (General)', 'Site Owner', 'Speaking (Conference)', 'Speaking (Local)', 'Speaking (User group)', 'Technical Social Media (Twitter, Facebook, LinkedIn...)', 'Translation Review, Feedback and Editing', 'User Group Owner', 'Video', 'Webcast', 'WebSite Posts')]
        [string]$contribution,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$description,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [int]$quantity = 1,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$reach,
        
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [validateset('ARM & DevOps on Azure (Chef, Puppet, Salt, Ansible, Dev/Test Lab)', 'Azure App Service', 'Azure Backup & Recovery', 'Azure Compute (VM, VMSS, Cloud Services)', 'Azure Container Services (Docker, Windows Server)', 'Azure Networking', 'Azure Security', 'Azure Storage', 'SDK support on Azure (.NET, Node.js, Java, PHP, Python, GO, Ruby)', 'Azure Stack', 'Chef/Puppet in Datacenter', 'Container Management', 'Datacenter Management', 'High Availability', 'PowerShell', 'Azure SQL Database', 'Python')]
        [string]$technology = 'ARM & DevOps on Azure (Chef, Puppet, Salt, Ansible, Dev/Test Lab)',
        
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$title,
        
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$url,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [validateset('Microsoft', 'MVP Community', 'Everyone', 'Microsoft Only')]
        [string]$visibility = 'Everyone',

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [datetime]$when = (Get-Date)
    )
    
    if (!(Get-MVPProfile)) {
	Set-MVPConfiguration -SubscriptionKey (Get-AzKeyVaultSecret -VaultName vaulty -Name mvp-api-subscription-key).secretvaluetext
    }
    $splat = @{
        StartDate              = $when
        Title                  = $title
        Description            = $description
        ReferenceUrl           = $url
        AnnualQuantity         = $quantity
        AnnualReach            = $reach
        Visibility             = $visibility
        ContributionType       = $contribution
        ContributionTechnology = $technology
    }
    New-MVPContribution @splat
}

function bloh-me([string]$title, [string]$tags) {
    docker run --rm -it -v 'C:/_/bloh:/tmp/jinja' python:3.6-jessie /bin/bash -c "cd /tmp/jinja/ && pip install -r requirements.txt && python new_post.py -t '$title' -s '$tags'"
}

function New-BashStyleAlias([string]$name, [string]$command) {
    $sb = [scriptblock]::Create($command)
    New-Item "Function:\global:$name" -Value $sb | Out-Null
}

Set-Alias -Name k -Value kubectl
New-BashStyleAlias kg 'kubectl get @args'
New-BashStyleAlias kd 'kubectl describe @args'
New-BashStyleAlias ka 'kubectl apply -f @args'
New-BashStyleAlias kr 'kubectl delete @args'
New-BashStyleAlias ke 'kubectl exec -it @args'
New-BashStyleAlias kl 'kubectl logs @args'

function develop-me() {
        if ( !$automationSecret ) { $automationSecret = $env:autoKey }
	$webhook = "https://s1events.azure-automation.net/webhooks?token=$automationSecret"
	Invoke-RestMethod -Method Post -Uri $webhook -Body ( @{ tada = (irm httpbin.org/ip).origin } | ConvertTo-Json )
}

function token-me() {
	$context = Get-AzureRmContext
	$cache = $context.TokenCache
	$cacheItem = $cache.ReadItems()
	$cacheItem
}

function azure-me() {
	$cred = [pscredential]::new($env:AZURE_CLIENT_ID,(ConvertTo-SecureString -String $env:AZURE_CLIENT_SECRET -AsPlainText -Force))
	Add-AzAccount -TenantId $env:AZURE_TENANT_ID -ServicePrincipal -SubscriptionName MSDN -Credential $cred
}

function secret-me() {
	Enable-AzContextAutosave
	[Environment]::SetEnvironmentVariable("AZURE_TENANT_ID", (Get-AzKeyVaultSecret -VaultName vaulty -Name azureTenantID).secretvaluetext, "User")
	[Environment]::SetEnvironmentVariable("AZURE_CLIENT_ID", (Get-AzKeyVaultSecret -VaultName vaulty -Name azureClientID).secretvaluetext, "User")
	[Environment]::SetEnvironmentVariable("AZURE_CLIENT_SECRET", (Get-AzKeyVaultSecret -VaultName vaulty -Name azureClientSecret).secretvaluetext, "User")
	[Environment]::SetEnvironmentVariable("autoKey", (Get-AzKeyVaultSecret -VaultName vaulty -Name autoKey).secretvaluetext, "User")
}

function debug-me() { Set-PSBreakpoint -Variable StackTrace -Mode Write }

Import-Module posh-git,mvp; $GitPromptSettings.AfterText += "`n"
$PSDefaultParameterValues["Out-Default:OutVariable"] = "lw"; cd "C:\_"; cls
