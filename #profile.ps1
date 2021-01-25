Set-PSReadLineKeyHandler -Chord 'Ctrl+a' -ScriptBlock {
    param($key, $arg)
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(0)
}
Set-PSReadLineKeyHandler -Chord 'Ctrl+e' -ScriptBlock {
    param($key, $arg)
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(1000000)
}

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

# tools
Set-Alias -Name d -Value docker
Set-Alias -Name k -Value kubectl
Set-Alias -Name f -Value fluxctl
Set-Alias -Name i -Value istioctl

# pwsh internal
New-Alias -Name ctj -Value ConvertTo-Json
New-Alias -Name cfj -Value ConvertFrom-Json

# kubectl
New-BashStyleAlias kk   'kubectl config @args'
New-BashStyleAlias kkg  'kubectl config get-contexts @args'
New-BashStyleAlias kks  'kubectl config set-context @args'
New-BashStyleAlias kd   'kubectl describe @args'
New-BashStyleAlias ka   'kubectl apply -f @args'
New-BashStyleAlias kr   'kubectl delete @args'
New-BashStyleAlias kra  'kubectl delete --all @args'
New-BashStyleAlias kl   'kubectl logs @args'
New-BashStyleAlias kf   'kubectl port-forward @args'
New-BashStyleAlias ke   'kubectl edit @args'
New-BashStyleAlias kc   'kubectl create @args'
New-BashStyleAlias ks   'kubectl scale @args'
New-BashStyleAlias kx   'kubectl exec @args'
New-BashStyleAlias kxi  'kubectl exec -it @args'
New-BashStyleAlias kt   'kubectl top @args'
New-BashStyleAlias kta  'kubectl top @args --all-namespaces'
New-BashStyleAlias kg   'kubectl get @args'
New-BashStyleAlias kgo  'kubectl get -o yaml --export @args'
New-BashStyleAlias kgj  'kubectl get -o json --export @args'
New-BashStyleAlias kga  'kubectl get --all-namespaces @args'
New-BashStyleAlias kgaj 'kubectl get --all-namespaces -o json @args'
New-BashStyleAlias kapi 'kubectl api-resources @args'

# docker
function dsa($name) { docker start $name; docker attach $name }
function drr($image) { docker run -it --rm $image }
function dga() { docker ps -a }
function dgi() { docker images }
function dra() { docker rm $(docker ps -qa) }
function dxi($image) { docker run -it $image bash }
function dxe($image) { docker run -d --entrypoint '/bin/bash' $image -c 'sleep 1000000' }
New-BashStyleAlias 'dri @args'
New-BashStyleAlias 'dr @args'

function New-NodeTunnel {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ArgumentCompleter( { @( (kg no -o jsonpath='{.items[*].metadata.name}').Split() -like $args[2] + '*') } )]
    [string]$nodeName,
    [Parameter(Mandatory = $false)]
    [string]$image = "docker.io/library/alpine",
    [Parameter(Mandatory = $false)]
    [string]$podName = "nsenter-$(Get-Random -Minimum 100000 -Maximum 999999)"
  )

  $tempFile = New-TemporaryFile
  @"
apiVersion: v1
kind: Pod
metadata:
    name: $podName
    namespace: default
spec:
    nodeName: $nodeName
    hostPID: true
    containers:
    - securityContext: 
        privileged: true
      image: $image
      name: nsenter
      stdin: true
      stdinOnce: true
      tty: true
      command:
      - "nsenter"
      - "--target"
      - "1"
      - "--mount"
      - "--uts"
      - "--ipc"
      - "--net"
      - "--pid"
      - "--"
      - "bash"
      - "-l"
"@ > $tempFile.FullName

  kubectl apply -f $tempFile.FullName
  kubectl attach -n default $podName -it
  kubectl delete pod -n default $podname
  Remove-Item $tempFile.FullName
}

function Get-HelmReleaseData ( $releaseName ) {
    $tempFile = ( New-TemporaryFile ).FullName
    $data = kubectl get secrets $releaseName -o jsonpath='{.data.release}'
    [System.IO.File]::WriteAllLines($tempFile, $data, (New-Object System.Text.UTF8Encoding $False))

    $dockerArgs = "run", "-it", "--rm", "--entrypoint", "bash", "-v", "${tempFile}:/raw", "debian:buster-slim", "-c", "base64 -d raw | base64 -d | gzip -d"
    $content = docker $dockerArgs | Select-Object -Skip 1
    ( $content | ConvertFrom-Json ).manifest
}

function Sleep-Container ($targetName, $targetType) {
    $targetJson = kubectl get $targetType $targetName -o json | ConvertFrom-Json
    $tempFile = New-TemporaryFile
    "spec:
      template:
        spec:
          containers:
          - name: $($targetJson.spec.template.spec.containers[0].name)
            command: ['sh','-c','sleep 10000s']" > $tempFile.FullName
    
    kubectl patch $targetType $targetName -p (Get-Content -Raw $tempFile.FullName)
    Remove-Item $tempFile
}

function kns {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
	[ArgumentCompleter( { @( (kubectl get namespaces -o jsonpath='{.items[*].metadata.name}').Split() -like $args[2] + '*') } )]
        [string]$namespace
    )
    kubectl config set-context (kubectl config current-context) --namespace $namespace
    # kubectl config set-context (kubectl config  get-contexts | sls -Pattern '^\*\s+(\w+)').matches.groups[1].value --namespace $namespace
}

function gca {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$workItemId,
        [Parameter(Mandatory = $true)]
        [string]$commitMessage,
	[switch]$commitAll
    )
    $commitMessage = '#{0}: {1}' -f $workItemId, $commitMessage
    if ($commitAll.IsPresent) {
        git add -A
    } else {
        git add -u
    }
    git commit -m $commitMessage
}

function dcr {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$localPath,
	[string]$image = "ci"
    )
    docker run -it -v C:\_\${localPath}:/ci $image
}

function develop-me() {
    if ( !$automationSecret ) { $automationSecret = $env:autoKey }
    $webhook = "https://s1events.azure-automation.net/webhooks?token=$automationSecret"
    Invoke-RestMethod -Method Post -Uri $webhook -Body ( @{ tada = (irm httpbin.org/ip).origin } | ConvertTo-Json )
}

function token-me {
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    if (!$azProfile.Accounts.Count) {
        Throw "Ensure you have logged in before calling this function."    
    }
  
    $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
    $token = $profileClient.AcquireAccessToken((Get-AzContext).Tenant.TenantId)

    if (!$token.AccessToken) {
        Throw "No Token"
    }
    @{ Authorization = "Bearer {0}" -f $token.AccessToken }
}

function timestamp-me {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$resourceId,
        [Parameter(Mandatory=$false)]
        [int]$timeRange = 72
    )

    $arr = $resourceId -split '/'
    $subscriptionId = $arr[2]
    $resourceType = "{0}/{1}" -f $arr[6], $arr[7]
    $resourceName = $arr[-1]

    $apiVersions = ( Get-AzResourceProvider -ProviderNamespace $arr[6] ).ResourceTypes
    $apiVersion = $apiVersions.where{ $_.ResourceTypeName -eq $arr[7] }.ApiVersions | Select-Object -First 1

    $Uri = "https://management.azure.com/subscriptions/{0}/resources?`$filter=name eq '{1}' and resourceType eq '{2}'&`$expand=createdTime&api-version={3}"
    $result = Invoke-RestMethod -Headers (token-me) -Uri ( $uri -f $subscriptionId, $resourceName, $resourceType, $apiVersion )

    if(!$result.value.createdTime) {
       Throw "No 'CreatedTime' property"
    }
    $result.value.createdTime
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
function copy-last( $name ) { Set-Variable -Name $name -Value $lw.clone() }

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Import-Module posh-git,mvp; $GitPromptSettings.AfterText += "`n"; $ENV:FLUX_FORWARD_NAMESPACE="flux"; $env:KUBE_EDITOR='code --wait'
$PSDefaultParameterValues["Out-Default:OutVariable"] = "lw"; cd "C:\_"; cls
