# pwsh
function debug-me() { Set-PSBreakpoint -Variable StackTrace -Mode Write }
function copy-me( $name ) { Set-Variable -Name $name -Value $lw.clone() }
New-Alias -Name ctj -Value ConvertTo-Json
New-Alias -Name cfj -Value ConvertFrom-Json
New-Alias -Name d -Value docker
New-Alias -Name k -Value kubectl
New-Alias -Name f -Value fluxctl
New-Alias -Name i -Value istioctl

Set-PSReadLineKeyHandler -Chord 'Ctrl+a' -ScriptBlock {
    param($key, $arg)
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(0)
}
Set-PSReadLineKeyHandler -Chord 'Ctrl+e' -ScriptBlock {
    param($key, $arg)
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(1000000)
}
function New-BashStyleAlias([string]$name, [string]$command) {
    $sb = [scriptblock]::Create($command)
    New-Item "Function:\global:$name" -Value $sb | Out-Null
}

# docker
New-BashStyleAlias dr  'docker rm @args'
New-BashStyleAlias dri 'docker rmi @args'
function dsa($name) { docker start $name; docker attach $name }
function dgi() { docker images }
function dga() { docker ps -a }
function dra() { docker rm $(docker ps -qa) }
function dxi($image) { docker run --rm -it $image bash }
function dxe($image) { docker run --rm -d --entrypoint '/bin/bash' $image -c 'sleep 1000000' }
function dcr {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$localPath,
	[string]$image = "ci"
    )
    docker run -it -v C:\_\${localPath}:/ci $image
}

# kubernetes
New-BashStyleAlias kk   'kubectl config @args'
New-BashStyleAlias kkg  'kubectl config get-contexts @args'
New-BashStyleAlias kks  'kubectl config set-context @args'
New-BashStyleAlias kku  'kubectl config use-context @args'
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
New-BashStyleAlias kgo  'kubectl get -o yaml @args'
New-BashStyleAlias kgj  'kubectl get -o json @args'
New-BashStyleAlias kga  'kubectl get --all-namespaces @args'
New-BashStyleAlias kgaj 'kubectl get --all-namespaces -o json @args'
New-BashStyleAlias kapi 'kubectl api-resources @args'
function kns {
    Param(
        [Parameter(Mandatory = $true)]
	[ArgumentCompleter( { @( (kubectl get namespaces -o jsonpath='{.items[*].metadata.name}').Split() -like $args[2] + '*') } )]
        [string]$namespace
    )
    kubectl config set-context (kubectl config current-context) --namespace $namespace
}

function node-me {
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

# https://gist.github.com/DzeryCZ/c4adf39d4a1a99ae6e594a183628eaee
function helm-me ( $releaseName ) {
    $tempFile = ( New-TemporaryFile ).FullName
    $data = kubectl get secrets $releaseName -o jsonpath='{.data.release}'
    [System.IO.File]::WriteAllLines($tempFile, $data, (New-Object System.Text.UTF8Encoding $False))

    $dockerArgs = "run", "-it", "--rm", "--entrypoint", "bash", "-v", "${tempFile}:/raw", "debian:buster-slim", "-c", "base64 -d raw | base64 -d | gzip -d"
    $content = docker $dockerArgs | Select-Object -Skip 1
    ( $content | ConvertFrom-Json ).manifest
    
    Remove-Item $tempFile
}

function secret-me ( $secretName ) {
    $secret = kubectl get secret -o json $secretName | ConvertFrom-Json
    $secret.data.PSObject.Properties.foreach{
        @{ $PSItem.Name = [System.Text.Encoding]::UTF8.GetString( [System.Convert]::FromBase64String( $PSItem.Value ) ) }
    }
}

function suspend-me ($targetName, $targetType) {
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

# azure
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

# miscellaneous
function commit-me {
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

function workhour-me {
    $now = Get-Date
    (1..[DateTime]::DaysInMonth($now.Year, $now.Month)).where{( Get-Date -Day $_ ).DayOfWeek -in 1..5 }.count * 8
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues["Out-Default:OutVariable"] = "lw"
$GitPromptSettings.AfterText += "`n"
$ENV:FLUX_FORWARD_NAMESPACE="flux"
Set-Location "$home\onedrive\_git"
$env:KUBE_EDITOR='code --wait'
Import-Module posh-git,mvp
Clear-Host
