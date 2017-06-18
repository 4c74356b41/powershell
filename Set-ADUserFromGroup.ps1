<#
.Synopsis
   Sets users attributes according to group membership.
.DESCRIPTION
   Sets users attributes according to group membership. Checks specified groups,
   runs through all members of those groups and sets attributes depending
   on group membership.
.EXAMPLE
   Set-ADUserFromGroup -DataForParameterOne Office1 -DataForParameterTwo City2 -DataForParameterThree Company3
   
   Sets first group members attribute Office to Office1,
   sets second group members attribute City to City2,
   sets third group members attribute Company to Company3.
   If a user is a member of several groups "earlier" write wins:
   Group 1 has priority over Group 2 and Group 3.
   Group 2 has priority over Group 3.
.EXAMPLE
   Set-ADUserFromGroup -FirstGroup Grp1 -SecondGroup Grp2 -ThirdGroup Grp3 -ParameterOne Country -ParameterTwo Department -ParameterThree Fax -DataForParameterOne Country1 -DataForParameterTwo Department2 -DataForParameterThree Fax3
   
   Sets Grp1 members attribute Country to Country1,
   sets Grp2 members attribute Department to Department2,
   sets Grp3 members attribute Fax to Fax3.
   If a user is a member of several groups "earlier" write wins:
   Group 1 has priority over Group 2 and Group 3.
   Group 2 has priority over Group 3.
#>
function Set-ADUserFromGroup
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $FirstGroup = 'Group 1',
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        $SecondGroup = 'Group 2',
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        $ThirdGroup = 'Group 3',
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        $ParameterOne = 'Office',
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        $ParameterTwo = 'City',
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        $ParameterThree = 'Company',
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        $DataForParameterOne = 'Group 1 Data',
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        $DataForParameterTwo = 'Group 2 Data',
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        $DataForParameterThree = 'Group 3 Data'
    )

$FirstGroupMembers = Get-ADGroupMember $FirstGroup
$SecondGroupMembers = Get-ADGroupMember $SecondGroup
$ThirdGroupMembers = Get-ADGroupMember $ThirdGroup



#region Working with Group 1

    $args = @{
        $ParameterOne = $DataForParameterOne
    }

foreach ($user in $FirstGroupMembers.samaccountname) {
    Set-ADUser $user @args
}
#endregion


#region Working with Group 2
$SecondGroupvsFirstGroup = Compare-Object $SecondGroupMembers.samaccountname $FirstGroupMembers.samaccountname
$SecondGroupMembersFinal = $SecondGroupvsFirstGroup | Where-Object {$_.SideIndicator -eq '<='}

    $args = @{
        $ParameterTwo = $DataForParameterTwo
    }

foreach ($user in $SecondGroupMembersFinal.InputObject.samaccountname) {
    Set-ADUser $user @args
}
#endregion


#region Working with Group 3

$FirstGroupandSecondGroupMembers = $FirstGroupMembers.samaccountname + $SecondGroupMembers.samaccountname | Select-Object -Unique
$ThirdGroupvsFirstGroupandSecondGroup = Compare-Object $ThirdGroupMembers.samaccountname $FirstGroupandSecondGroupMembers
$ThirdGroupMembersFinal = $ThirdGroupvsFirstGroupandSecondGroup | Where-Object {$_.SideIndicator -eq '<='}

    $args = @{
        $ParameterThree = $DataForParameterThree
    }

foreach ($user in $ThirdGroupMembersFinal.InputObject) {
    Set-ADUser $user @args
}
#endregion
}
