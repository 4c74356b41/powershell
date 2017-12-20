function token-me {
	Param()
	$azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
	$currentAzureContext = Get-AzureRmContext
	$profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile)
	$token = $profileClient.AcquireAccessToken($currentAzureContext.Subscription.TenantId)
	$token.AccessToken
}

function develop-me {
	Param()
	$webhook = "https://s1events.azure-automation.net/webhooks?token=$automationSecret"
	$whbody  = @{ tada = ((iwr httpbin.org/ip).content | convertfrom-json).origin } | ConvertTo-Json
	Invoke-RestMethod -Method Post -Uri $webhook -Body $whbody
}

function docker-me {
  Param(
  [string]$clientId=$env:AZURE_CLIENT_ID,
  [string]$clientSecret=$env:AZURE_CLIENT_SECRET,
  [string]$tenant=$env:AZURE_TENANT_ID
  [string]$subscription=$MSDN,
  [string]$image='dops',
  [string]$mappotaDep='B:\bb\azure\deployment:/home/deployment',
  [string]$mappotaOut='B:\bb\_envs:/etc/ansible/output'
  )
  docker run -it --rm -v $mappotaDep -v $mappotaOut -e "AZURE_CLIENT_ID=`"$clientId`"" -e "AZURE_SECRET=`"$clientSecret`"" -e "AZURE_SUBSCRIPTION_ID=`"$subscription`"" -e "AZURE_TENANT=`"$tenant`"" $image
}

function misc-me {
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
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [validateset('Article', 'Blog Site Posts', 'Book (Author)', 'Book (Co-Author)', 'Sample Project/Tools', 'Sample Code', 'Conference (booth presenter)', 'Conference (organizer)', 'Forum Moderator', 'Forum Participation (3rd Party forums)', 'Forum Participation (Microsoft Forums)', 'Mentorship', 'Open Source Project(s)', 'Other', 'Product Group Feedback (General)', 'Site Owner', 'Speaking (Conference)', 'Speaking (Local)', 'Speaking (User group)', 'Technical Social Media (Twitter, Facebook, LinkedIn...)', 'Translation Review, Feedback and Editing', 'User Group Owner', 'Video', 'Webcast', 'WebSite Posts')]
        [string]$contribution,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
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
        
        [Parameter(Mandatory = $true, ValueFrozPipelineByPropertyName = $true)]
        [string]$url,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [validateset('Microsoft', 'MVP Community', 'Everyone', 'Microsoft Only')]
        [string]$visibility = 'Everyone',

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [datetime]$when
    )
    
    if (!(Get-MVProfile)) {
	Set-MVPConfiguration -SubscriptionKey (Get-AzureKeyVaultSecret -VaultName vaulty -Name subKey).secretvaluetext
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

function secret-me {
	Param()
	[Environment]::SetEnvironmentVariable("AZURE_TENANT_ID", (Get-AzureKeyVaultSecret -VaultName vaulty -Name azureTenantID).secretvaluetext, "User")
	[Environment]::SetEnvironmentVariable("AZURE_CLIENT_ID", (Get-AzureKeyVaultSecret -VaultName vaulty -Name azureClientID).secretvaluetext, "User")
	[Environment]::SetEnvironmentVariable("AZURE_CLIENT_SECRET", (Get-AzureKeyVaultSecret -VaultName vaulty -Name azureClientSecret).secretvaluetext, "User")
}

$PSDefaultParameterValues["Out-Default:OutVariable"] = "lw"
import-module posh-git

Add-AzureRmAccount -TenantId $env:AZURE_TENANT_ID -ServicePrincipal -SubscriptionName MSDN `
 -Credential ([pscredential]::new($env:AZURE_CLIENT_ID,(ConvertTo-SecureString -String $env:AZURE_CLIENT_SECRET -AsPlainText -Force)))
 
$automationSecret = (Get-AzureKeyVaultSecret -VaultName vaulty -Name autoKey).secretvaluetext
$msdn = (Get-AzureKeyVaultSecret -VaultName vaulty -Name subMSDN).secretvaluetext
$mvp = (Get-AzureKeyVaultSecret -VaultName vaulty -Name subMVP).secretvaluetext
$mct = (Get-AzureKeyVaultSecret -VaultName vaulty -Name subMCT).secretvaluetext

cd \
cls 

# PATH="$HOME/bin:$HOME/.local/bin:$PATH"
# PATH="$PATH:/mnt/c/Program\ Files/Docker/Docker/resources/bin"
# alias docker="docker.exe"
