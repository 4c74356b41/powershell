choco install jre8 -PackageParameters "/exclude:64" -y
choco install tomcat -y -x86 -version 7.0.69 -ignoredependencies -params "unzipLocation=C:\\web"
choco install apache-httpd -y -x86 -packageParameters '"/unzipLocation:C:\web /serviceName:Apache HTTPD 2.4.X"'

docker pull microsoft/powershell --platform=linux
docker pull microsoft/azure-cli --platform=linux
docker build -t dops . --platform=linux
docker pull microsoft/aspnet:4.7.1
docker pull microsoft/dotnet-framework:4.7.1

#creds\session
[Runtime.InteropServices.Marshal]::PtrToStringAuto;[Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass)
(Get-Credential).Password | ConvertFrom-SecureString | Out-File -FilePath blabla.cred
$cred = New-Object System.Management.Automation.PsCredential "dom\usr",( Get-Content blabla.cred | ConvertTo-SecureString )
$cred = [pscredential]::new('administrator',(ConvertTo-SecureString -String '!Q2w3e4r' -AsPlainText -Force))
$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://fqdn/powershell/ -Credential $cred -Authentication Kerberos -AllowRedirection

#misc
Set-PSBreakpoint -Variable StackTrace -Mode Write
([adsi]"WinNT://./Administrators,group").Add("WinNT://DOMAIN/grpname,group") #username,user
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "machineA,machineB" # "*"
Invoke-WmiMethod -Class win32_process -name Create -ComputerName dflt -Credential $cred -ArgumentList "powershell.exe -noprofile -noninteractive -executionpolicy bypass -encodedCommand "
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#get hyper-v report
Invoke-Command -ComputerName 'hostname' -ScriptBlock { Get-VM | Get-VMProcessor | ? { $_.CompatibilityForMigrationEnabled -eq $false } | fl VMname, CompatibilityForMigrationEnabled }
Get-VM | Format-Table Name, IntegrationServicesVersion
Get-VM | Measure-VM | select VMName, @{ Label='TotalIO';Expression = { $_.AggregatedDiskDataRead + $_.AggregatedDiskDataWritten }}, @{ Label='%Read';Expression={"{0:P2}" -f ($_.AggregatedDiskDataRead/($_.AggregatedDiskDataRead + $_.AggregatedDiskDataWritten))}}, @{Label='%Write';Expression={"{0:P2}" -f ($_.AggregatedDiskDataWritten/($_.AggregatedDiskDataRead + $_.AggregatedDiskDataWritten))}}, @{Label='TotalIOPS';Expression = {"{0:N2}" -f (($_.AggregatedDiskDataRead + $_.AggregatedDiskDataWritten)/$_.MeteringDuration.Seconds)}}
#set hdd iops limits
Get-VM -ComputerName 'hostname' | % {
    Set-VMHardDiskDrive -ComputerName 'hostname' -VMName $_.VMName -ControllerType $_.HardDrives.ControllerType `
    -ControllerNumber $_.HardDrives.ControllerNumber -ControllerLocation $_.HardDrives.ControllerLocation `
    -MinimumIOPS 0 -MaximumIOPS 500
}
#get fibre adapters
$data = Get-WmiObject -namespace "root\wmi" -class MSFC_FibrePortNPIVAttributes -computer 'hostname'
$data | select WWPN | % {[array]::Reverse($_.WWPN); [BitConverter]::ToUInt64($_.WWPN, 0).ToString("X") }
wmic /node:computername product where 'vendor like "Microsoft%"'
#nat switch
New-VMSwitch -SwitchName “NATSwitch” -SwitchType Internal
New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceAlias “vEthernet (NATSwitch)”
New-NetNAT -Name “NATNetwork” -InternalIPInterfaceAddressPrefix 192.168.0.0/24

#import mailboxes from folder
gci something | % { New-MailboxImportRequest -Mailbox $($_ -replace ".{4}$") -FilePath $_.FullName -BadItemLimit 300 -LargeItemLimit 50 -AcceptLargeDataLoss }
#replace something in files
gci path -Filter * -Recurse | % { ( gci $_.FullName | % { $_ -replace '','' } ) | sc $_.FullName }
#get files older then x
( gci -Recurse | ? { $_.LastWriteTime -gt (get-date).addyears(-5) } | Measure-Object -sum -Property Length ).sum/1gb

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
