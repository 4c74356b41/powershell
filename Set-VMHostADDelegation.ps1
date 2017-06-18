function Set-VMHostADDelegation
{
	<#
	.SYNOPSIS
		Sets Active Directory delegation on specified hosts for SMB transfers and/or Live Migration.
	.DESCRIPTION
		Sets Active Directory delegation on specified hosts for SMB transfers and/or Live Migration.
	.PARAMETER TargetHost
		One or more Active Directory computers that will be added to the allowed delegate list of the source host.
		Can be supplied as a string array or an array of Microsoft.ActiveDirectory.Management.ADComputer.
	.PARAMETER SourceHost
		One or Active Directory computers that will allow delegation to the target computer account(s).
		Can be supplied as a string array or an array of Microsoft.ActiveDirectory.Management.ADComputer.
	.PARAMETER LiveMigration
		If set, the specified source system(s) will allow delegation for the 'Microsoft Virtual System Migration Service' to the designated target(s).
	.PARAMETER SMB
		If set, the specified source system(s) will allow delegation for the 'CIFS' service to the designated target(s).
	.PARAMETER Reciprocate
		If set, all items in the source and target lists will be used as sources and targets for all the other items in both lists.
		If this parameter is set, neither SourceHost or SourceHostObject need to be specified.
	.INPUTS
		System.String
		Microsoft.ActiveDirectory.Management.ADComputer
	.OUTPUTS
		None
	.NOTES
		Set-VMHostADDelegation.ps1
		Version 1.0
		February 21, 2016
		Author: Eric Siron
		(c) 2016 Altaro Software
	.EXAMPLE
		Set-VMHostADDelegation -SourceHost hyperv1 -TargetHost hyperv2 -LiveMigration
		Gives the host named 'hyperv1' the ability to present credentials to 'hyperv2' for Kerberos-based Live Migrations
	.EXAMPLE
		Set-VMHostADDelegation -SourceHost hyperv1 -TargetHost hyperv2 -LiveMigration -Reciprocate
		Gives the hosts named 'hyperv1' and 'hyperv2' the ability to present credentials to each other for Kerberos-based Live Migrations.
	.EXAMPLE
		Set-VMHostADDelegation -TargetHost 'hyperv1', 'hyperv2' -Reciprocate
		Exactly the same outcome as example 2.
	.EXAMPLE
		Set-VMHostADDelegation -TargetHost (Get-ADComputer -Filter 'Name -like "hyper*"') -SMB -LiveMigration -Reciprocate
		Gives every computer in the domain whose name starts with "hyper" the ability to present credentials to every other computer in the domain whose name starts with "hyper" for SMB operations and Kerberos-based Live Migrations.
	.EXAMPLE
		Set-VMHostADDelegation -TargetHost (Get-ADComputer -Filter 'Name -like "hyper*"') -SMB -LiveMigration -Reciprocate
		Gives every computer in the domain whose name starts with "hyper" the ability to present credentials to every other computer in the domain whose name starts with "hyper" for SMB operations and Kerberos-based Live Migrations.
	#>
	#requires -Module ActiveDirectory
	[CmdletBinding(DefaultParameterSetName='By Names', SupportsShouldProcess)]
	param
	(
		[Parameter(Mandatory=$true, Position=1)][PSObject[]]$TargetHost,
		[Parameter(Position=2)][PSObject[]]$SourceHost = @(),
		[Parameter()][Switch]$LiveMigration,
		[Parameter()][Switch]$SMB,
		[Parameter()][Switch]$Reciprocate
	)
	Write-Verbose 'Verifying input...'
	if($SourceHost.Count -eq 0 -and -not $Reciprocate)
	{
		throw 'If no source host is specified, the Reciprocate switch must be set.'
	}
	if(-not($SMB.ToBool() -bor $LiveMigration.ToBool()))
	{
		throw('You must select the SMB switch, the LiveMigration switch, or both.')
	}
	$DelegationServices = @()
	if($SMB)
	{
		$DelegationServices += 'cifs'
	}
	if($LiveMigration)
	{
		$DelegationServices += 'Microsoft Virtual System Migration Service'
	}
	Write-Verbose -Message 'Extracting fully-qualified domain names...'
	$TargetHostGroup = @()
	$SourceHostGroup = @()
	$TargetHostType = $TargetHost[0].GetType()
	$SourceHostType = $null
	if($TargetHostType.FullName -eq 'System.String')
	{
		Write-Verbose -Message 'Targets supplied as strings. Verifying Active Directory accounts...'
		foreach($HostName in $TargetHost)
		{
			Write-Verbose -Message ('Retrieving computer object for {0}...' -f $HostName)
			try
			{
				$Computer = Get-ADComputer -Identity $HostName -ErrorAction Stop
				Write-Verbose -Message ('Adding {0} to the target list...')
				$TargetHostGroup += $Computer.DNSHostName
				if($Reciprocate)
				{
					Write-Verbose -Message ('Reciprocate flag set, copying {0} to the source list...' -f $Computer.DNSHostName)
					$SourceHostGroup += $Computer
				}
			}
			catch
			{
				Write-Error -Message $_.Message # this try/catch just prevents entering blank lines in the target host group
			}
		}
	}
	elseif($TargetHostType.FullName -eq 'Microsoft.ActiveDirectory.Management.ADComputer')
	{
		Write-Verbose -Message 'Targets supplied as strings. Extracting fully-qualified domain names...'
		foreach($Computer in $TargetHost)
		{
			Write-Verbose -Message ('Adding {0} to the target list...')
			$TargetHostGroup += $Computer.DNSHostName
			Write-Verbose -Message ('Reciprocate flag set, copying {0} to the source list...' -f $Computer.DNSHostName)
			$SourceHostGroup += $Computer
		}
	}
	else
	{
		$Arg = New-Object System.Management.Automation.PSArgumentException(('Type {0} is invalid for the TargetHost parameter. Only String and ADComputer objects are accepted.' -f $TargetHostType), 'TargetHost')
		throw($Arg)
	}
	if($SourceHost.Count)
	{
		$SourceHostType = $SourceHost[0].GetType()
		if($SourceHostType.FullName -eq 'System.String')
		{
			foreach($HostName in $SourceHost)
			{
				Write-Verbose -Message 'Sources supplied as strings. Retrieving Active Directory objects...'
				try
				{
					$Computer = Get-ADComputer -Identity $HostName -ErrorAction Stop
					if($SourceHostGroup -notcontains $Computer) # might have been populated by reciprocate action
					{
						Write-Verbose -Message ('Adding {0} to the source list...')
						$SourceHostGroup += $Computer
						if($Reciprocate)
						{
							if($TargetHostGroup -notcontains $Computer.DNSHostName)
							{
								Write-Verbose -Message ('Reciprocate flag set, copying {0} to the target list...' -f $Computer.DNSHostName)
								$TargetHostGroup += $Computer.DNSHostName
							}
						}
					}
				}
				catch
				{
					Write-Error -Message $_.Message # this try/catch just prevents entering empty objects to the source host group
				}
			}
		}
		elseif($SourceHostType.FullName -eq 'Microsoft.ActiveDirectory.Management.ADComputer')
		{
			$SourceHostGroup = $SourceHost
			if($Reciprocate)
			{
				if($TargetHostGroup -notcontains $Computer.DNSHostName)
				{
					Write-Verbose -Message ('Reciprocate flag set, copying {0} to the target list...' -f $Computer.DNSHostName)
					$TargetHostGroup += $Computer.DNSHostName
				}
			}
		}
		else
		{
			$Arg = New-Object System.Management.Automation.PSArgumentException(('Type {0} is invalid for the SourceHost parameter. Only String and ADComputer objects are accepted.' -f $SourceHostType), 'SourceHost')
			throw($Arg)
		}
	}
	foreach($Computer in $SourceHostGroup)
	{
		foreach($Service in $DelegationServices)
		{
			foreach($TargetComputerName in $TargetHostGroup)
			{
				if($Computer.DNSHostName.ToLower() -ne $TargetComputerName.ToLower())
				{
					if($PSCmdlet.ShouldProcess($Computer.DNSHostName.ToLower(), ('Present credentials to {0} for {1} operations' -f $TargetComputerName, $Service)))
					{
						Set-ADObject -Identity $Computer -Add @{'msDS-AllowedToDelegateTo' = ('{0}/{1}' -f $Service, $TargetComputerName) }
					}
				}
			}
		}
	}
}
