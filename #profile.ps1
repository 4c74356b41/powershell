function debug-me() { Set-PSBreakpoint -Variable StackTrace -Mode Write }
function copy-me( $name ) { New-Variable -Name $name -Value $lw.clone() -Scope Global }
New-Alias -Name ctj -Value ConvertTo-Json
New-Alias -Name cfj -Value ConvertFrom-Json
New-Alias -Name d -Value docker
New-Alias -Name k -Value kubectl
New-Alias -Name f -Value flux
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
    [string]$image = "ci",
    [string]$entryPoint = "/bin/bash",
    [string]$port = "3000"
  )
  docker run -it --entrypoint=$entryPoint -p ${port}:${port} -v c:\_git\${localPath}:/ci $image
}

# kubernetes
New-BashStyleAlias kk   'kubectl config @args'
New-BashStyleAlias kkg  'kubectl config get-contexts @args'
New-BashStyleAlias kks  'kubectl config set-context @args'
New-BashStyleAlias kku  'kubectl config use-context @args'
New-BashStyleAlias kd   'kubectl describe @args'
New-BashStyleAlias kdbg 'kubectl debug @args'
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

function kdn {
  Param(
    [Parameter(Mandatory = $true)]
    [ArgumentCompleter( { @( (kubectl get node -oname).Split() -like $args[2] + '*') } )]
    [string]$node,
    [string]$image = "busybox"
  )
  kubectl debug -it $node --image=$image
}

function helm-me ($helmRelease) {
  $namespace = kubectl config view --minify -o jsonpath='{..namespace}'
  $resources = helm get manifest $helmRelease | k apply -f - --dry-run=client
  $resources.foreach{
    $res = $_.Split() | Select -First 1
    kubectl label $res app.kubernetes.io/managed-by=Helm
    kubectl annotate $res meta.helm.sh/release-name=$helmRelease
    kubectl annotate $res meta.helm.sh/release-namespace=$namespace
  }
}

function get-k8s-api-deprecation {
  (kubectl get --raw /metrics | sls '^apiserver_requested_deprecated_apis')
}

function istio-debug-me {
  param(
    [Parameter(Mandatory=$false)]
    [ArgumentCompleter( { @( "admin","alternate_protocols_cache","aws","assert","backtrace","cache_filter","client","config","connection","conn_handler","decompression","dns","dubbo","envoy_bug","ext_authz","rocketmq","file","filter","forward_proxy","grpc","happy_eyeballs","hc","health_checker","http","http2","hystrix","init","io","jwt","kafka","key_value_store","lua","main","matcher","misc","mongo","quic","quic_stream","pool","rbac","redis","router","runtime","stats","secret","tap","testing","thrift","tracing","upstream","udp","wasm" -like $args[2] + '*') } )]
    [string]$logger
  )
  if ( [string]::IsNullOrEmpty($logger) ) {
    $log = "level"
  } else {
    $log = $logger
  }
  $job = istio-gateway-pf-me
  Invoke-RestMethod "http://localhost:15000/logging?$log=debug" -Method:Post
  $job | Remove-Job -Force
}

function istio-gateway-me ([switch]$internal) {
  $selector = "istio=ingressgateway"
  if ($internal) { $selector = "istio=ingressgateway-internal" }
  kubectl get pods --namespace istio-system --selector $selector -oname | Get-Random
}

function istio-gateway-pf-me {
  Start-Job -ScriptBlock {
    kubectl port-forward $args[0] --namespace istio-system 15000
  } -ArgumentList $( istio-gateway-me )
}

function istio-gateway-config-me {
  $job = istio-gateway-pf-me
  $json = Invoke-WebRequest -UseBasicParsing http://localhost:15000/config_dump
  $json.content | Set-Clipboard
  $job | Remove-Job -Force
}

function istio-gateway-log-me {
  kubectl logs $( istio-gateway-me ) -n istio-system -f --since=1s istio-proxy
}

function secret-me ( $secretName ) {
  $secret = kubectl get secret -o json $secretName | ConvertFrom-Json
  $secret.data.PSObject.Properties.foreach{
      @{ $PSItem.Name = [System.Text.Encoding]::UTF8.GetString( [System.Convert]::FromBase64String( $PSItem.Value ) ) }
  }
}

function suspend-me ( $targetName, $targetType ) {
  $targetJson = kubectl get $targetType $targetName -o json | ConvertFrom-Json
  $tempFile = New-TemporaryFile
  "spec:
    template:
      spec:
        containers:
        - name: $($targetJson.spec.template.spec.containers[0].name)
          command: ['sh','-c','sleep 10000s']" > $tempFile.FullName

  kubectl patch $targetType $targetName -p ( Get-Content -Raw $tempFile.FullName )
  Remove-Item $tempFile
}

# azure
New-Alias -Name nrg -Value New-AzResourceGroup
New-Alias -Name sld -Value New-AzDeployment
New-Alias -Name rgd -Value New-AzResourceGroupDeployment

function timestamp-me {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [string]$resourceId,
    [Parameter(Mandatory=$false)]
    [string]$apiVersion = "2022-09-01"
  )

  $arr = $resourceId -split '/'
  $subscriptionId = $arr[2]
  $resourceType = "{0}/{1}" -f $arr[6], $arr[7]
  $resourceName = $arr[-1]

  $Uri = "https://management.azure.com/subscriptions/{0}/resources?`$filter=name eq '{1}' and resourceType eq '{2}'&`$expand=createdTime&api-version={3}"
  $response = Invoke-AzRest -Uri ( $uri -f $subscriptionId, $resourceName, $resourceType, $apiVersion )
  $result = $response.Content | ConvertFrom-Json

  if( -not $result.value.createdTime ) { Throw "No 'CreatedTime' property" }
  $result.value.createdTime
}

# miscellaneous
Set-Location "c:\_git\"
Import-Module posh-git
$GitPromptSettings.DefaultPromptSuffix.Text = ""
$GitPromptSettings.DefaultPromptBeforeSuffix.Text = ' [$(get-date -Format "hh:mm:ss dd-MM-yyyy")]`n'
$GitPromptSettings.DefaultPromptPath.Text = '$( ( Get-PromptPath ) -replace "C:\\_git","#" )'
$GitPromptSettings.DefaultPromptAbbreviateGitDirectory = $true
$PSDefaultParameterValues["Out-Default:OutVariable"] = "lw"
Set-PSReadLineOption -PredictionViewStyle ListView -PredictionSource History
New-BashStyleAlias gtp 'git commit -am typo; git push'
New-BashStyleAlias gtc 'git commit -am @args'
New-BashStyleAlias gpf 'git pull --ff-only @args'
New-BashStyleAlias gfa 'git fetch --all --prune @args'
New-BashStyleAlias gba 'git branch -a @args'
New-BashStyleAlias gb 'git branch @args'

function workhour-me ([int]$offset, $hours = 8) {
  $now = Get-Date
  $month = $now.Month + $offset
  ( 1..[DateTime]::DaysInMonth( $now.Year, $month) ).where{
    ( Get-Date -Day $_ -Month $month ).DayOfWeek -in 1..5
  }.count * $hours
}
function base64-file-me ($b64, $filename = "b64.temp") {
  $bytes = [Convert]::FromBase64String($b64)
  [IO.File]::WriteAllBytes("$pwd/$filename", $bytes)
}
function hosts-me {
  code C:\Windows\System32\drivers\etc\hosts
}

Start-Job -ScriptBlock {
  param ( $profilePath )
  $tempFile = ( New-TemporaryFile ).FullName
  Invoke-RestMethod "https://raw.githubusercontent.com/4c74356b41/powershell/master/%23profile.ps1" -ErrorAction Stop > $tempFile
  $tempContent = Get-Content -Raw $tempFile
  $profileHash = ( Get-FileHash $profilePath ).hash
  $tempProfileHash = ( Get-FileHash $tempFile ).hash
  if ( $profileHash -ne $tempProfileHash -and -not [string]::IsNullOrEmpty( $tempContent ) ) {
    "update!"
    Move-Item $tempFile $profilePath -Force
  }
} -ArgumentList $profile

Clear-Host
