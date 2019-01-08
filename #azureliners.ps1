# get provider api-versions
(Get-AzResourceProvider -ProviderNamespace 'Microsoft.Insights').ResourceTypes | FT ResourceTypeName, ApiVersions

# get all operations
$ops = (Get-AzProviderOperation -OperationSearchString */*).Operation

# specifics (https://resource.azure.com)
Get-AzProviderOperation -OperationSearchString Microsoft.Cdn/* | Where { $_.Operation -like '*action' } | Format-Table 
Invoke-AzResourceAction -ResourceGroupName $rg -ResourceType 'Microsoft.Cdn/profiles/endpoints' -ResourceName $ProfileName/$EndpointName `
    -ApiVersion '2015-06-01' -Action 'Purge' -Parameters @{ ContentPaths = '/*' } -Force

# "advanced" shroubletooting
$logentry = Get-AzLog -CorrelationId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -DetailedOutput
$rawStatusMessage = $logentry.Properties
$status = $rawStatusMessage.Content.statusMessage | ConvertFrom-Json

# providerz
Get-AzResourceProvider -ListAvailable | select ProviderNamespace
Get-AzResourceProvider -ListAvailable | where{$_.ProviderNamespace -like "*compute"} | foreach-object{Register-AzResourceProvider -ProviderNamespace $_.ProviderNamespace}

# new role
$role = Get-AzRoleDefinition "Virtual Machine Contributor"
$role.Id = $null
$role.Name = "Classic storage reader"
$role.Actions.Clear()
$role.Actions.Add("Microsoft.ClassicStorage/storageAccounts/read")
$role.AssignableScopes.Clear()
$role.AssignableScopes.Add("/subscriptions/xxxx")
New-AzRoleDefinition -Role $role
