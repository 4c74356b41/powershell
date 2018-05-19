function kg([string[]]$passMe) { kubectl get $passMe }
function ka([string[]]$passMe) { kubectl apply -f $passMe }
function kr([string[]]$passMe) { kubectl delete $passMe }
function kd([string[]]$passMe) { kubectl describe $passMe }
function ke([string[]]$passMe) { kubectl exec -it $passMe }
function kl([string[]]$passMe) { kubectl logs $passMe }

function develop-me() {
        if ( !$automationSecret ) { $automationSecret = $env:autoKey }
	$webhook = "https://s1events.azure-automation.net/webhooks?token=$automationSecret"
	Invoke-RestMethod -Method Post -Uri $webhook -Body "{ tada = $((irm httpbin.org/ip).origin) }"
}

function ssh-me() {
    Get-Content B:\_envs\cis\ssh\api-gateway\api-gateway.txt
    Get-Content B:\_envs\cis\otherPasswords\pwdmcrsrv
    Invoke-Expression "ssh -i B:\_envs\cis\ssh\api-gateway\api-gateway.pem -L 23389:10.5.0.31:3389 cis-api-gateway.bbrmt.com -l cis-api-gateway -N"
}

function token-me() {
	$context = Get-AzureRmContext
	$cache = $context.TokenCache
	$cacheItem = $cache.ReadItems()
	$cacheItem
}

function docker-me {
    Param(
        [string]$user=$env:AZURE_CLIENT_ID,
        [string]$pswd=$env:AZURE_CLIENT_SECRET,
        [string]$tenant=$env:AZURE_TENANT_ID,
        [string]$subId=$MSDN,
        [switch]$spn,

        [string]$image='dops',
        [string]$mapDeps='B:\azure\deployment:/home/deployment',
        [string]$mapOut='B:\_envs:/etc/ansible/output'
    )
    $str = 'docker run -it --rm -v {0} -v {1} -e AZURE_SUBSCRIPTION_ID="{2}" -e AZURE_TENANT="{3}" -e {4}="{5}" -e {6}="{7}" {8}'
    if ( $spn.IsPresent ) {
        $userReplace = 'AZURE_CLIENT_ID'
        $pswdReplace = 'AZURE_SECRET'
    } else {
        $userReplace = 'AZURE_AD_USER'
        $pswdReplace = 'AZURE_PASSWORD'
    }

    $invoke = $str -f $mapDeps, $mapOut, $subId, $tenant, $userReplace, $user, $pswdReplace, $pswd, $image
    iex $invoke
}

function misc-me() {
	git config --global user.email "4c74356b41@outlook.com"
	git config --global user.name "Gleb Boushev"
	"https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-windows"
}

function get-image {
	Param(
        [string]$pub,
        [string]$offer,
        [string]$sku
    )
    if ($sku) {
        Get-AzureRmVMImage -Location eastus -PublisherName $pub -Offer $offer -Skus $sku | select version
    }
    else {
        Get-AzureRmVMImageSku -Location eastus -Publisher $pub -Offer $offer
    }
}

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
	Set-MVPConfiguration -SubscriptionKey (Get-AzureKeyVaultSecret -VaultName vaulty -Name subApi).secretvaluetext
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

function secret-me() {
	Enable-AzureRmContextAutosave
	[Environment]::SetEnvironmentVariable("AZURE_TENANT_ID", (Get-AzureKeyVaultSecret -VaultName vaulty -Name azureTenantID).secretvaluetext, "User")
	[Environment]::SetEnvironmentVariable("AZURE_CLIENT_ID", (Get-AzureKeyVaultSecret -VaultName vaulty -Name azureClientID).secretvaluetext, "User")
	[Environment]::SetEnvironmentVariable("AZURE_CLIENT_SECRET", (Get-AzureKeyVaultSecret -VaultName vaulty -Name azureClientSecret).secretvaluetext, "User")
}

function azure-me() {
	Add-AzureRmAccount -TenantId $env:AZURE_TENANT_ID -ServicePrincipal -SubscriptionName MSDN `
		-Credential ([pscredential]::new($env:AZURE_CLIENT_ID,(ConvertTo-SecureString -String $env:AZURE_CLIENT_SECRET -AsPlainText -Force)))
}

function get-me-secret() {
	$global:msdn = (Get-AzureKeyVaultSecret -VaultName vaulty -Name subMSDN).secretvaluetext
	$global:mvp = (Get-AzureKeyVaultSecret -VaultName vaulty -Name subMVP).secretvaluetext
	$global:mct = (Get-AzureKeyVaultSecret -VaultName vaulty -Name subMCT).secretvaluetext
	$global:automationSecret = (Get-AzureKeyVaultSecret -VaultName vaulty -Name autoKey).secretvaluetext
}

function debug-me() {
	Set-PSBreakpoint -Variable StackTrace -Mode Write
}
try { Import-Module azurerm,posh-git,mvp -ErrorAction Stop} catch { Install-Module azurerm,posh-git,mvp -Confirm }
$GitPromptSettings.AfterText += "`n"; $PSDefaultParameterValues["Out-Default:OutVariable"] = "lw"; b:; cls
