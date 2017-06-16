function Move-VDIUserAndProfile {

    <#
    .SYNOPSIS
    Takes users and computers from a CSV file and migrates user data
    .DESCRIPTION
		Feed CSV file into it along with OU you want to move users into and paths to root folders of users profiles
    (old one and new one). Users need to be logged out. Profiles are moved with robocopy,
    PCs are tested with ping and should be accessible by WMI.
	.PARAMETER FilePath
		Path to your CSV file. CSV file should be formatted with headers pc,user or this script will fail
	.PARAMETER TargetOU
		Specify OU to which user accounts should be moved
	.PARAMETER BasePath
		Specify path where old user profiles reside
	.PARAMETER TargetPath
		Specife path where to move user profiles with Robocopy
	.PARAMETER LogOperationalPath
		Path for operational log file
	.PARAMETER LogRebootPath
		Path for log file with a list of rebooted PCs
	.PARAMETER LogCopyPath
		Robocopy log file
	.INPUTS
		System.String
	.OUTPUTS
		Some logging stuff only
	.EXAMPLE
		Move-VDIUserAndProfile -FilePath c:\vdi.csv -TargetOU NewVDIOU -BasePath \\fileserver\oldprofiles -TargetPath \\fileserver\newprofiles
		Grabs c:\vdi.csv scans all pcs and shuts them off if appropriate after that moves user data from \\fileserver\oldprofiles to \\fileserver\newprofiles
    #>
  
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true,HelpMessage="Path to CSV",ValueFromPipeline=$true)]
        [string]$FilePath,

        [parameter(Mandatory=$true,HelpMessage="Target OU Name",ValueFromPipeline=$true)]
        [string]$TargetOU,

        [parameter(Mandatory=$true,HelpMessage="Old profile root path",ValueFromPipeline=$true)]
        [string]$BasePath,

        [parameter(Mandatory=$true,HelpMessage="New profile root path",ValueFromPipeline=$true)]
        [string]$TargetPath,

        [parameter(Mandatory=$false,HelpMessage="Log file path",ValueFromPipeline=$true)]
        [string]$LogOperationalPath = "$PSScriptRoot\Operational.log",

        [parameter(Mandatory=$false,HelpMessage="Log of rebooted PCs path",ValueFromPipeline=$true)]
        [string]$LogRebootPath = "$PSScriptRoot\reboot.log",

        [parameter(Mandatory=$false,HelpMessage="Robocopy log path",ValueFromPipeline=$true)]
        [string]$LogCopyPath = "$PSScriptRoot\copy.log"
            )

    ##Some sanity checks ##
    if (!(Get-PSSnapin -Registered -Name Citrix.Broker.Admin.V2) -or !(Get-Module -ListAvailable -Name ActiveDirectory))
        {
            "[Timestamp: $(get-date -Format hh:mm:ss)][error]Missing prerequisites (AD Module or Citrix.Broker.Admin.V2)" |
            Tee-Object $LogOperationalPath -Append
            Exit
        }
        
    Import-Module activedirectory
    Add-PSSnapin Citrix.Broker.Admin.V2

    ## Script Body ##
    $csv = Import-CSV $FilePath 
    foreach ($_ in $csv) 
        { 
            $pc = $_.pc
            $user = $_.user
            "[Timestamp: $(get-date -Format hh:mm:ss)]$pc : checking PC" | Tee-Object $LogOperationalPath -Append 

            ## Part 0: establishing connection ##
            $ping = Test-NetConnection $pc  
            
            if ($ping.PingSucceeded) { 
                Try {
                    $objWMI_pc_computer_system = Get-WmiObject -Class Win32_ComputerSystem -computername $pc 
                    If ($objWMI_pc_computer_system.UserName.length -gt 0) { 
                        "[Timestamp: $(get-date -Format hh:mm:ss)][error]$pc : user $objWMI_pc_computer_system.UserName logged on - skipping" | Tee-Object $LogOperationalPath -Append 
                    }

                    else { 
                        ## Part 1: Move and Reboot PC ##                    
                        $target = Get-ADOrganizationalUnit -LDAPFilter "(name=$TargetOU)"
                        Get-ADComputer $pc | Move-ADObject -TargetPath $target.DistinguishedName
                        "[Timestamp: $(get-date -Format hh:mm:ss)]$pc : Moved to $TargetOU " | Tee-Object $LogOperationalPath -Append
                        
                        "[Timestamp: $(get-date -Format hh:mm:ss)]$pc : turned off" | Tee-Object $LogRebootPath -Append 
                        New-BrokerHostingPowerAction -Action ShutDown -MachineName $pc
                        ## you might want to issue start sleep here ##

                        ## Part 2: Move User Profile ##
                        $Param = $BasePath + $user +'.V2' + ' ' + $TargetPath + $user + '.V2' + ' ' +'/E'
                        $CopyProc = (Start-Process -Credential user robocopy.exe -ArgumentList $Param -wait -PassThru )
                        "[Timestamp: $(get-date -Format hh:mm:ss)]Copy code: $CopyProc.ExitCode" | Tee-Object $LogOperationalPath -append 

                        $userAD = Get-ADUser $user -Properties ProfilePath  
                        "[Timestamp: $(get-date -Format hh:mm:ss)]Old data: $userAD.ProfilePath" | Tee-Object $LogCopyPath -append 
                        $userAD.ProfilePath = $TargetPath+"%username%" 
                        "[Timestamp: $(get-date -Format hh:mm:ss)]New data: $userAD.ProfilePath" | Tee-Object $LogCopyPath -append 
                        Set-ADUser -instance $userAD
                    } 
                } 

                Catch [System.UnauthorizedAccessException] {
                    "[Timestamp: $(get-date -Format hh:mm:ss)][error] $pc : WMI access denied" | Tee-Object $LogOperationalPath -Append
                }

                Catch {
                    "[Timestamp: $(get-date -Format hh:mm:ss)]$Error[0]" | Tee-Object $LogOperationalPath -Append
                }
            }
            else {
                "[Timestamp: $(get-date -Format hh:mm:ss)][error] $pc : not pingable, skipping" | Tee-Object $LogOperationalPath -Append 
        }
    }
}
