function contribute-me {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [validateset('Article','Blog/Website Post','Book (Author)','Book (Co-Author)','Conference (Staffing)','Docs.Microsoft.com Contribution','Forum Moderator','Forum Participation (3rd Party forums)','Forum Participation (Microsoft Forums)','Mentorship','Microsoft Open Source Projects','Non-Microsoft Open Source Projects','Organizer (User Group/Meetup/Local Events)','Organizer of Conference','Other','Product Group Feedback','Sample Code/Projects/Tools','Site Owner','Speaking (Conference)','Speaking (User Group/Meetup/Local events)','Technical Social Media (Twitter, Facebook, LinkedIn...)','Translation Review, Feedback and Editing','Video/Webcast/Podcast','Workshop/Volunteer/Proctor')]
        [string]$contribution,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$description,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [int]$quantity = 1,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$reach,
        
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [validateset('ARM & DevOps on Azure (Chef, Puppet, Salt, Ansible, Dev/Test Lab)','Azure App Service','Azure Backup & Recovery','Azure Blockchain','Azure Compute (VM, VMSS, HPC/Batch, Cloud Services)','Azure Container Services (Docker, Windows Server)','Azure IoT','Azure Networking','Azure Security and Compliance','Azure Service Fabric','Azure Stack','Azure Storage','Enterprise Integration','SDK support on Azure (.NET, Node.js, Java, PHP, Python, GO, Ruby)')]
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
Set-Alias -Name f -Value fluxctl
Set-Alias -Name i -Value istioctl
New-BashStyleAlias kk  'kubectl config @args'
New-BashStyleAlias kd  'kubectl describe @args'
New-BashStyleAlias ka  'kubectl apply -f @args'
New-BashStyleAlias kr  'kubectl delete @args'
New-BashStyleAlias kl  'kubectl logs @args'
New-BashStyleAlias kt  'kubectl top @args'
New-BashStyleAlias kf  'kubectl port-forward @args'
New-BashStyleAlias ke  'kubectl edit @args'
New-BashStyleAlias kc  'kubectl create @args'
New-BashStyleAlias ks  'kubectl scale @args'
New-BashStyleAlias kx  'kubectl exec @args'
New-BashStyleAlias kxi 'kubectl exec -it @args'
New-BashStyleAlias kg  'kubectl get @args'
New-BashStyleAlias kgo 'kubectl get -o yaml --export @args'
New-BashStyleAlias kga 'kubectl get --all-namespaces @args'

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

function pulumi-me-mi-me-mi-me-mi() {
	azure-me
	$env:ARM_CLIENT_ID=$ENV:AZURE_CLIENT_ID
	$env:ARM_TENANT_ID=$ENV:AZURE_TENANT_ID
	$env:ARM_SUBSCRIPTION_ID=(Get-AzContext).Subscription.Id
	$env:ARM_CLIENT_SECRET=$ENV:AZURE_CLIENT_SECRET
}

function secret-me() {
	Enable-AzContextAutosave
	[Environment]::SetEnvironmentVariable("AZURE_TENANT_ID", (Get-AzKeyVaultSecret -VaultName vaulty -Name azureTenantID).secretvaluetext, "User")
	[Environment]::SetEnvironmentVariable("AZURE_CLIENT_ID", (Get-AzKeyVaultSecret -VaultName vaulty -Name azureClientID).secretvaluetext, "User")
	[Environment]::SetEnvironmentVariable("AZURE_CLIENT_SECRET", (Get-AzKeyVaultSecret -VaultName vaulty -Name azureClientSecret).secretvaluetext, "User")
	[Environment]::SetEnvironmentVariable("autoKey", (Get-AzKeyVaultSecret -VaultName vaulty -Name autoKey).secretvaluetext, "User")
}

function debug-me() { Set-PSBreakpoint -Variable StackTrace -Mode Write }

Import-Module posh-git,mvp; $GitPromptSettings.AfterText += "`n"; $ENV:FLUX_FORWARD_NAMESPACE="flux"
$PSDefaultParameterValues["Out-Default:OutVariable"] = "lw"; cd "C:\_"; cls
