# initial setup
set-executionpolicy unrestricted
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install -y kubernetes-cli kubernetes-helm istioctl openshift-cli fluxctl
choco install -y git 7zip vscode vlc microsoft-teams slack telegram
if (!(Invoke-RestMethod -Headers @{"Metadata"="true"} 'http://169.254.169.254/metadata/instance?api-version=2018-10-01')) {
    choco install -y docker-desktop
}
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
install-module posh-git,mvp,az,az.resourcegraph
git config --global user.email "core@4c74356b41.com"
git config --global user.name "Gleb Boushev"
git config --global core.eol lf
git config --global core.autocrlf input
'Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/4c74356b41/powershell/master/%23profile.ps1")' > $profile

#creds\session
[Runtime.InteropServices.Marshal]::PtrToStringAuto;[Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass)
(Get-Credential).Password | ConvertFrom-SecureString | Out-File -FilePath blabla.cred
$cred = New-Object System.Management.Automation.PsCredential "dom\usr",( Get-Content blabla.cred | ConvertTo-SecureString )
$cred = [pscredential]::new('administrator',(ConvertTo-SecureString -String '!Q2w3e4r' -AsPlainText -Force))

# misc
([adsi]"WinNT://./Administrators,group").Add("WinNT://DOMAIN/grpname,group") #username,user
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "machineA,machineB" # "*"
Invoke-WmiMethod -Class win32_process -name Create -ComputerName dflt -Credential $cred -ArgumentList "powershell.exe -noprofile -noninteractive -executionpolicy bypass -encodedCommand "

# replace something in files
gci path -Filter * -Recurse | % { ( gci $_.FullName | % { $_ -replace '','' } ) | sc $_.FullName }
# get files older then x
( gci -Recurse | ? { $_.LastWriteTime -gt (get-date).addyears(-5) } | Measure-Object -sum -Property Length ).sum/1gb

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
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# degen group-object
$skips = { "streak": 3, "game": 940 }
( $skips | Group-Object streak )[x].group.foreach{}
