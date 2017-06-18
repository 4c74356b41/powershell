$user = 'xxxxx'
$PlainPassword = 'xxxxx'
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $User, $SecurePassword

$msoExchangeURL = “https://ps.outlook.com/powershell/”

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $msoExchangeURL -Credential $cred -Authentication Basic -AllowRedirection -ErrorAction stop
					Connect-MsolService -Credential $cred -ErrorAction stop
					Import-PSSession $session

$csv = $null
$csv = Import-Csv c:\_.csv -Encoding Default
foreach ($item in $csv) {
$dp = $null
$dp = $item.FirstName + ' ' + $item.LastName
        
New-MsolUser -UserPrincipalName $item.UPN -FirstName $item.FirstName -LastName $item.LastName -DisplayName $dp`
-Password $item.Password -StrongPasswordRequired $False -ForceChangePassword $true -LicenseAssignment "xxxxx" -UsageLocation RU
Set-MsolUserLicense -UserPrincipalName $item.UPN -AddLicenses "xxxxx"

#$user = $null
#$user = Get-MsolUser -UserPrincipalName $item.UPN
#Add-MsolGroupMember -GroupObjectId xxxxx -GroupMemberObjectId $user.objectid
}
