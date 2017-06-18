$csv = Import-CSV "C:\Users\testo\Desktop\_.txt" -Delimiter "`t"

[Reflection.Assembly]::LoadWithPartialName("System.Web") 

# Create OU's and dept's

$departments = New-Object System.Collections.ArrayList
$region   = $csv[0].Region

if (!(test-path "AD:\OU=$region,OU=Access,OU=SibGroups,DC=xxx,DC=xxx"))
    {New-ADOrganizationalUnit -Name $region -Path "OU=Access,OU=SibGroups,DC=xxx,DC=xxx"}

foreach ($_ in $csv) {

    [void]$departments.add($_.department)

    if ($_.Department.Length -ge 64) {
        $_.Department = $_.Department.Substring(0,64)
    }


    if (!(test-path "AD:\OU=$region,OU=StaffRegions,OU=SibUsers,DC=xxx,DC=xxx"))
        {New-ADOrganizationalUnit -Name $region -Path "OU=StaffRegions,OU=SibUsers,DC=xxx,DC=xxx"}
    if (!(test-path "AD:\OU=$($_.City),OU=$region,OU=StaffRegions,OU=SibUsers,DC=xxx,DC=xxx"))
        {New-ADOrganizationalUnit -Name $_.City -Path "OU=$region,OU=StaffRegions,OU=SibUsers,DC=xxx,DC=xxx"}
    if (!(test-path "AD:\OU=$($_.Department),OU=$($_.City),OU=$region,OU=StaffRegions,OU=SibUsers,DC=xxx,DC=xxx"))
        {New-ADOrganizationalUnit -Name $_.Department -Path "OU=$($_.City),OU=$region,OU=StaffRegions,OU=SibUsers,DC=xxx,DC=xxx"}
}
$departmentsunique = $departments | select -Unique

#region Creating Users

# Create User
foreach ($_ in $csv) {

    if ($_.Department.Length -ge 64) {
        $_.Department = $_.Department.Substring(0,64)
    }
    [string]$password = $null
    [string]$path = "OU=$($_.Department),OU=$($_.City),OU=$region,OU=StaffRegions,OU=SibUsers,DC=xxx,DC=xxx"
    $ADuser = Get-ADUser -Filter "sAMAccountName -eq '$($_.SamAccountName)'"
    $pattern = "^(?=.*[^a-zA-Z])(?=.*[a-z])(?=.*[A-Z])\S{8,}$"

    while (!($password -match $pattern)) {
        $password = [System.Web.Security.Membership]::GeneratePassword(9,2)
    }

    $args = @{
        DisplayName = $_.DisplayName 
        GivenName = $_.GivenName
        Surname = $_.sn
        SamAccountName = $_.SamAccountName
        UserPrincipalName = $($_.SamAccountName + "@xxx.xxx")
        Department = $_.Department
        Title = $_.Title
        City = $_.City
        Office = $_.Office
        MobilePhone = $_.MobilePhone
        OfficePhone = $_.telephoneNumber
        Name = $_.DisplayName
        Company = "xxx"
        Path = $path
        State = $region
    }

    if ($ADuser) {
        "$(Get-Date -Format hh:mm:ss)[error]: User exists $ADUser" | Out-File c:\log.txt -Append
    }

    else {
        Try {
        New-ADUser @args -PassThru | ForEach-Object {
            $_ | Set-ADAccountPassword -Reset -NewPassword (ConvertTo-SecureString -Force -AsPlainText $password )
            $_ | Enable-ADAccount
            "$(Get-Date -Format hh:mm:ss): $($_.samaccountname) with   $password   created" | Out-File c:\log.txt -Append
}}
        Catch {
            "$(Get-Date -Format hh:mm:ss)[error]: Failed creating user $($_.TargetObject)" | Out-File c:\log.txt -Append
}}}

# Add Manager
foreach ($_ in $csv) {
    Get-ADUser $_.samaccountname | Set-ADUser -Manager $(Get-ADUser -Filter "Name -eq '$($_.manager)'" -ea 0)
}

#endregion

#region Creating and Populating Groups

# Create Groups
New-ADGroup -Name "$region" -SamAccountName "$region" -GroupScope Global -GroupCategory Security -Path "OU=Role,OU=SibGroups,DC=xxx,DC=xxx"
$pathgrp = "OU=$region,OU=Access,OU=SibGroups,DC=xxx,DC=xxx"

foreach ($department in $departmentsunique) {

    $groupshortname = $null
    [regex]::Matches($department, '\b[а-я]', 'IgnoreCase') | % { $groupshortname += $_.Value }

    $groupname = $region + '_' + $groupshortname

    New-ADGroup -Name $groupname -DisplayName $("$region $department") -GroupScope Global -GroupCategory Security -Path "OU=Role,OU=SibGroups,DC=xxx,DC=xxx"
    New-ADGroup -Name $("FS_G_" + $groupname + "_LS") -DisplayName $("FS_G_" + $region + $department + "_LS") -GroupScope DomainLocal -GroupCategory Security -Path $pathgrp
    New-ADGroup -Name $("FS_G_" + $groupname + "_RO") -DisplayName $("FS_G_" + $region + $department + "_RO") -GroupScope DomainLocal -GroupCategory Security -Path $pathgrp
    New-ADGroup -Name $("FS_G_" + $groupname + "_WR") -DisplayName $("FS_G_" + $region + $department + "_WR") -GroupScope DomainLocal -GroupCategory Security -Path $pathgrp
    Add-ADPrincipalGroupMembership -Identity $("FS_G_" + $groupname + "_RO") -MemberOf $("FS_G_" + $groupname + "_LS")
    Add-ADPrincipalGroupMembership -Identity $("FS_G_" + $groupname + "_WR") -MemberOf $("FS_G_" + $groupname + "_LS")
    Add-ADPrincipalGroupMembership -Identity $("FS_G_" + $groupname + "_WR") -MemberOf $("FS_G_" + $groupname + "_RO")
    Add-ADPrincipalGroupMembership -Identity $groupname -MemberOf $("FS_G_" + $groupname + '_WR')
}

#Assign Users to Groups
foreach ($_ in $csv) {
    $groupshortname = $null
    [regex]::Matches($department, '\b[а-я]', 'IgnoreCase') | % { $groupshortname += $_.Value }

    $user = Get-ADUser -Filter "sAMAccountName -eq '$($_.SamAccountName)'"
    $group = Get-ADGroup -Filter "sAMAccountName -eq '$($region + '_' + $groupshortname)'"
    Add-ADGroupMember $group –Member $user
    Add-ADGroupMember $region -Member $user
}
#endregion
