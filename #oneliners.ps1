# delete PSREADLINE module first
# initial setup
Set-ExecutionPolicy Bypass -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
winget install 7zip.7zip, GitHub.cli, Microsoft.AzureCLI, Microsoft.VisualStudioCode, Git.Git
winget install Telegram.TelegramDesktop, 9NKSQGP7F2NH, 9WZDNCRDK3WP # wa\slack
winget install Kubernetes.kubectl, Helm.Helm, FluxCD.Flux, Microsoft.Bicep
# choco install -y kubernetes-cli kubernetes-helm stern bicep
# choco install -y git 7zip vscode telegram
# choco install -y slack istioctl flux gh
# choco install anydesk.portable --params="'/install'" -y

Install-PackageProvider -Name NuGet
Register-PSRepository -Default
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
install-module posh-git,az,psreadline,microsoft.graph

# https://docs.microsoft.com/en-us/windows/wsl/install-manual
Enable-WindowsOptionalFeature -Online -FeatureName $("VirtualMachinePlatform", "Microsoft-Windows-Subsystem-Linux")
wsl --install -d ubuntu

git config --global user.email "core@4c74356b41.com"
git config --global user.name "Gleb Boushev"
git config --global core.eol lf
git config --global core.autocrlf input
git config --global --add --bool push.autoSetupRemote true
'Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/4c74356b41/powershell/master/%23profile.ps1")' > $profile
# https://docs.microsoft.com/en-us/windows/terminal/customize-settings/interaction#word-delimiters
(Get-PSReadlineOption).HistorySavePath

[Environment]::SetEnvironmentVariable("FLUX_SYSTEM_NAMESPACE", "flux-system", "USER")
[Environment]::SetEnvironmentVariable("KUBE_EDITOR", "code --wait", "USER")

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
