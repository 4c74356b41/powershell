#choco stuff
Install-PackageProvider -Name Chocolatey
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
choco install 7zip skype teamviewer putty vlc keepass notepadplusplus -y
choco install jre8 -PackageParameters "/exclude:64" -y
choco install tomcat -y -x86 -version 7.0.69 -ignoredependencies -params "unzipLocation=C:\\web"
choco install apache-httpd -y -x86 -packageParameters '"/unzipLocation:C:\web /serviceName:Apache HTTPD 2.4.X"'

#save creds
(Get-Credential).Password | ConvertFrom-SecureString | Out-File -FilePath blabla.cred
$scred = New-Object System.Management.Automation.PsCredential "dom\usr", `
 (Get-Content blabla.cred | ConvertTo-SecureString)
$exsession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://fqdn/powershell/ `
 -Credential $scred -Authentication Kerberos -AllowRedirection
#decrypt\crypt password
[Runtime.InteropServices.Marshal]::PtrToStringAuto
([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))
#add user to administrators
([adsi]"WinNT://./Administrators,group").Add("WinNT://DOMAIN/grpname,group")
([adsi]"WinNT://./Administrators,group").Add("WinNT://DOMAIN/username,user")
#create session
$args = @{
	PC = '172.20.15.100'
	cred = ([pscredential]::new('administrator',(ConvertTo-SecureString -String '!Q2w3e4r' -AsPlainText -Force)))
} # https://blogs.technet.microsoft.com/heyscriptingguy/2013/03/26/decrypt-powershell-secure-string-password/
$session = New-PSSession @args

#allow machine
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "machineA,machineB"
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*"

#launch powershell over wmi
Invoke-WmiMethod -Class win32_process -name Create -ComputerName dflt -Credential $cred -ArgumentList "powershell.exe -noprofile -noninteractive -executionpolicy bypass -encodedCommand "

#get hyper-v report
Invoke-Command -ComputerName msk-hpv-01 -ScriptBlock {Get-VM | Get-VMProcessor | ? {$_.CompatibilityForMigrationEnabled -eq $false} | fl VMname, CompatibilityForMigrationEnabled}
Get-VM | Format-Table Name, IntegrationServicesVersion
Get-VM | Measure-VM | select VMName, @{Label='TotalIO';Expression = {$_.AggregatedDiskDataRead + $_.AggregatedDiskDataWritten}}, @{Label='%Read';Expression={"{0:P2}" -f ($_.AggregatedDiskDataRead/($_.AggregatedDiskDataRead + $_.AggregatedDiskDataWritten))}}, @{Label='%Write';Expression={"{0:P2}" -f ($_.AggregatedDiskDataWritten/($_.AggregatedDiskDataRead + $_.AggregatedDiskDataWritten))}}, @{Label='TotalIOPS';Expression = {"{0:N2}" -f (($_.AggregatedDiskDataRead + $_.AggregatedDiskDataWritten)/$_.MeteringDuration.Seconds)}}

#set hdd iops limits
$srv = 'hostname'
$VMs = Get-VM -ComputerName $hpv
foreach ($_ in $VMs) {Set-VMHardDiskDrive -ComputerName $srv -VMName $_.VMName -ControllerType `
$_.HardDrives.ControllerType -ControllerNumber $_.HardDrives.ControllerNumber -ControllerLocation $_.HardDrives.ControllerLocation `
-MinimumIOPS 0 -MaximumIOPS 500}

#get fibre adapters
$data = Get-WmiObject -namespace "root\wmi" -class MSFC_FibrePortNPIVAttributes -computer $servername
$data | select WWPN | foreach {[array]::Reverse($_.WWPN); [BitConverter]::ToUInt64($_.WWPN, 0).ToString("X") }
wmic /node:computername product where 'vendor like "Microsoft%"'

#replace something in files
gci c:\_ -Filter * -Recurse | % {(gci $_.FullName | % {$_ -replace '',''}) | sc $_.FullName}

#get files older then x
(dir -Recurse -ea 0 | ? {$_.LastWriteTime -gt (get-date).addyears(-5)} | Measure-Object -sum -Property Length).sum/1gb

#import mailboxes from folder
gci something | % { New-MailboxImportRequest -Mailbox $($_ -replace ".{4}$") -FilePath $_.FullName -BadItemLimit 300 -LargeItemLimit 50 -AcceptLargeDataLoss }
