# https://github.com/projectkudu/ARMClient

function GetAuthToken
{
    param
    (
            [Parameter(Mandatory=$true)]
            $ApiEndpointUri,

            [Parameter(Mandatory=$true)]
            $AADTenant
    )
    $adal = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\" + `
                "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $adalforms = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\" + `
                    "Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"

    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

    $clientId = "1950a258-227b-4e31-a9cf-717495945fc2"
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    $authorityUri = “https://login.windows.net/$aadTenant”

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authorityUri

    $authResult = $authContext.AcquireToken($ApiEndpointUri, $clientId,$redirectUri, "Auto")

    return $authResult
}

$ApiEndpointUri = "https://management.azure.com/"
$AADTenant = 'GUID'
$token = GetAuthToken -ApiEndPointUri $ApiEndpointUri -AADTenant $AADTenant
$header = @{
	'Content-Type'='application\json'
	'Authorization'=$token.CreateAuthorizationHeader()
}

add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@

[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy # NO SSL

$request = ``
(Invoke-RestMethod -Uri $request -Headers $header -Method Get).value
