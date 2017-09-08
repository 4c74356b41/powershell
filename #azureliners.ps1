# get provider api-versions
(Get-AzureRmResourceProvider -ProviderNamespace 'Microsoft.Insights').ResourceTypes | FT ResourceTypeName, ApiVersions

# get all operations
$ops = (Get-AzureRmProviderOperation -OperationSearchString */*).Operation

# specifics (https://resource.azure.com)
Get-AzureRmProviderOperation -OperationSearchString Microsoft.Cdn/* | Where { $_.Operation -like '*action' } | Format-Table 
Invoke-AzureRmResourceAction -ResourceGroupName $rg -ResourceType 'Microsoft.Cdn/profiles/endpoints' -ResourceName $ProfileName/$EndpointName `
    -ApiVersion '2015-06-01' -Action 'Purge' -Parameters @{ ContentPaths = '/*' } -Force

# "advanced" shroubletooting
$logentry = Get-AzureRMLog -CorrelationId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -DetailedOutput
$rawStatusMessage = $logentry.Properties
$status = $rawStatusMessage.Content.statusMessage | ConvertFrom-Json

# providerz
Get-AzureRmResourceProvider -ListAvailable | select ProviderNamespace
Get-AzureRmResourceProvider -ListAvailable | where{$_.ProviderNamespace -like "*compute"} | foreach-object{Register-AzureRmResourceProvider -ProviderNamespace $_.ProviderNamespace}

# new role
$role = Get-AzureRmRoleDefinition "Virtual Machine Contributor"
$role.Id = $null
$role.Name = "Classic storage reader"
$role.Actions.Clear()
$role.Actions.Add("Microsoft.ClassicStorage/storageAccounts/read")
$role.AssignableScopes.Clear()
$role.AssignableScopes.Add("/subscriptions/xxxx")
New-AzureRmRoleDefinition -Role $role
