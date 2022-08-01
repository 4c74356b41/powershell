# initial setup
set-executionpolicy unrestricted
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install -y kubernetes-cli kubernetes-helm stern bicep
choco install -y git 7zip vscode telegram
choco install -y slack istioctl fluxctl
choco install anydesk.portable --params="'/install'"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet
Register-PSRepository -Default
install-module posh-git,az,az.resourcegraph,az.websites,az.managedserviceidentity,psreadline
import-module posh-git

git config --global user.email "core@4c74356b41.com"
git config --global user.name "Gleb Boushev"
git config --global core.eol lf
git config --global core.autocrlf input
'Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/4c74356b41/powershell/master/%23profile.ps1")' > $profile
# https://docs.microsoft.com/en-us/windows/terminal/customize-settings/interaction#word-delimiters
(Get-PSReadlineOption).HistorySavePath

# misc
$cred = [pscredential]::new('administrator',(ConvertTo-SecureString -String '!Q2w3e4r' -AsPlainText -Force))
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "machineA,machineB" # "*"
Invoke-WmiMethod `
    -Class win32_process `
    -name Create `
    -ComputerName dflt `
    -Credential $cred `
    -ArgumentList "powershell.exe -noprofile -noninteractive -executionpolicy bypass -encodedCommand "

# ssl stuff
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
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
