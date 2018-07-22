param(
    [object]$WebhookData
)

$uri = Get-AutomationVariable -Name "tgUri"
$chatId = Get-AutomationVariable -Name "tgChat"
$servicePrincipalConnection = Get-AutomationConnection -Name "AzureRunAsConnection"

function notifyMe($chatMessage) {
    $datota = @{
        uri             = $script:uri
        body            = @{
            chat_id = $script:chatId
            text    = $chatMessage
        }
        UseBasicParsing = $true
        ErrorAction     = 'Stop'
        Method          = 'Post'
    }
    invoke-restmethod @datota
}

function toggleVM($inputto) {
    notifyMe 'job started'
    $null = Add-AzureRmAccount `
        -ServicePrincipal -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
    $null = Select-AzureRmSubscription -SubscriptionId (Get-AutomationVariable -Name subId)
    $vm = Get-AzureRmVM -ResourceGroupName prx -Status

    if ($vm.Powerstate -match 'dealloc') {
        $vm | Start-AzureRmVM -asJob -ErrorAction Stop
        notifyMe 'starting vm'

        # Mofidy NSG to allow connections
        $nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName prx
        $nsg | Set-AzureRmNetworkSecurityRuleConfig -Name 'rdp_rule' `
            -Access Allow `
            -Protocol Tcp `
            -Direction Inbound `
            -Priority 777 `
            -SourceAddressPrefix $inputto `
            -SourcePortRange * `
            -DestinationAddressPrefix * `
            -DestinationPortRange 3389
        $nsg | Set-AzureRmNetworkSecurityGroup
    }
    else {
        $vm | Stop-AzureRmVM -Force -asJob -ErrorAction Stop
        notifyMe 'stopping vm'
    }
    notifyMe 'job done'
}

toggleVM ( $WebhookData.RequestBody | ConvertFrom-Json ).tada
