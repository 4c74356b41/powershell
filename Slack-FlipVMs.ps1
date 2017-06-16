workflow Shutdown-Start-VMs-By-Resource-Group
{
	Param
    (   
        [Parameter(Mandatory=$true)]
        [ValidateSet("csv","xml","clixml")]
        [String]
        $AzureResourceGroup,
		[Parameter(Mandatory=$true)]
        [string]
		$Shutdown,
        [Parameter(Mandatory=$true)]
        [String]
        $Tag
    )
	
    write-output $AzureResourceGroup
    $shutdown = [system.convert]::ToBoolean($shutdown)
	$connectionName = "AzureRunAsConnection"
	try
	{
	    # Get the connection "AzureRunAsConnection "
	    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         
	
	    $null = Add-AzureRmAccount `
	        -ServicePrincipal `
	        -TenantId $servicePrincipalConnection.TenantId `
	        -ApplicationId $servicePrincipalConnection.ApplicationId `
	        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
	}
	catch {
	    if (!$servicePrincipalConnection)
	    {
	        $ErrorMessage = "Connection $connectionName not found."
	        throw $ErrorMessage
	    } else{
	        Write-Error -Message $_.Exception
	        throw $_.Exception
	    }
	}
	
	#ARM VMs
	Get-AzureRmVM -ResourceGroupName $AzureResourceGroup | ForEach-Object {
        if($_.Tags.Values -contains $Tag) {
            if($Shutdown -eq $true){
                "Stopping '$($_.Name)' ...";
                $null = Stop-AzureRmVM -ResourceGroupName $AzureResourceGroup -Name $_.Name -Force;
            }
            else{
                "Starting '$($_.Name)' ...";			
                $null = Start-AzureRmVM -ResourceGroupName $AzureResourceGroup -Name $_.Name;			
            }	
        }		
	};
	
	#ASM VMs
	Get-AzureRmResource | where { $_.ResourceGroupName -match $AzureResourceGroup -and $_.ResourceType -eq "Microsoft.ClassicCompute/VirtualMachines"} | ForEach-Object {
		if($Shutdown -eq $true){
            if($_.PowerState -eq "Started"){
                "Stopping '$($_.Name)' ...";		
                $null = Stop-AzureVM -ServiceName $_.ServiceName -Name $_.Name -Force;
            }
		}
		else{		
            if($_.PowerState -eq "Stopped"){
                "Starting '$($_.Name)' ...";		
                $null = Start-AzureVM -ServiceName $_.ServiceName -Name $_.Name;
            }
		}		
	}

    return
}
