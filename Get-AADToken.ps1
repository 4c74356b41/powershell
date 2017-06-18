function Get-AADToken {
param
(
    [Parameter(Mandatory=$true)]
    $TenantName
)
    $adal = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $adalforms = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"
    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
    $clientId = "539e8a45-b940-465f-a782-c6239db43409" # = the Native Azure AD App Id
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    $resourceAppIdURI = "https://mysupercoolapi.azurewebsites.net" # Is the API App URI ID
    $authority = "https://login.microsoftonline.com/$TenantName"
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
    $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")
    return $authResult
}

$tenant = "tenant" 
$token = Get-AADToken -TenantName $tenant
$authHeader = @{
   'Content-Type'='application\json'
   'Authorization'= $token.CreateAuthorizationHeader()
}

Invoke-RestMethod -Method Get -Uri 'http://mysupercoolapi.azurewebsites.net/api/values' -Headers $authHeader -UseBasicParsing


#Azure Authtentication Token

#requires -Version 3
#SPN ClientId and Secret
$ClientID       = "clientid" #ApplicationID
$ClientSecret   = "ClientSecret"  #key from Application
$tennantid      = "TennantID"
 

$TokenEndpoint = {https://login.windows.net/{0}/oauth2/token} -f $tennantid 
$ARMResource = "https://management.core.windows.net/";

$Body = @{
        'resource'= $ARMResource
        'client_id' = $ClientID
        'grant_type' = 'client_credentials'
        'client_secret' = $ClientSecret
}

$params = @{
    ContentType = 'application/x-www-form-urlencoded'
    Headers = @{'accept'='application/json'}
    Body = $Body
    Method = 'Post'
    URI = $TokenEndpoint
}

$token = Invoke-RestMethod @params

$token | select access_token, @{L='Expires';E={[timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($_.expires_on))}} | fl *
