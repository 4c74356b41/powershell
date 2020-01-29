# get provider api-versions
( Get-AzResourceProvider -ProviderNamespace 'Microsoft.Insights' ).ResourceTypes | ft ResourceTypeName, ApiVersions

# get all operations
$ops = ( Get-AzProviderOperation -OperationSearchString '*/*' ).Operation

# specifics (https://resource.azure.com)
Get-AzProviderOperation -OperationSearchString 'Microsoft.Cdn/*' | ? { $_.Operation -match 'action$' } | ft 
Invoke-AzResourceAction -ResourceGroupName $rg -ResourceType 'Microsoft.Cdn/profiles/endpoints' `
    -ResourceName $ProfileName/$EndpointName -Force -Action 'Purge' `
    -ApiVersion '2015-06-01' -Parameters @{ ContentPaths = '/*' }

# "advanced" shroubletooting
$logentry = Get-AzLog -CorrelationId $guid -DetailedOutput
$rawStatusMessage = $logentry.Properties
$status = $rawStatusMessage.Content.statusMessage | ConvertFrom-Json

# providerz
Get-AzResourceProvider -ListAvailable | Select-Object ProviderNamespace
Get-AzResourceProvider -ListAvailable | Where-Object { $_.ProviderNamespace -match "compute" }
    | Foreach-Object { Register-AzResourceProvider -ProviderNamespace $_.ProviderNamespace }
