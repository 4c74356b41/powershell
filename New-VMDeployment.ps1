<#
.Synopsis
Creates a VM, attaches MDT Boot Image and boots it

.Description
It's brief

.Parameter SystemType
System Type of a VM

.Parameter Generation
Generation of a VM

.Parameter Reference
Is this VM a reference VM

#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,HelpMessage="System Type of a VM?")]
    [ValidateSet("x64","x86")]
    [String]$SystemType,

    [Parameter(Mandatory=$True,HelpMessage="Generation of a VM?")]
    [ValidateSet("1","2")]
    [int]$Generation,

    [Parameter(Mandatory=$True,HelpMessage="Is this VM a reference VM?")]
    [ValidateSet("Yes","No")]
    [String]$Reference,

    [String]$VMLocation = "C:\VMs",
    [String]$VMNetwork = "Private",
    [String]$VMName = "RefVM",
    [Int64]$VMMemory = 2048MB,
    [Int64]$VMDiskSize = 60GB
)

if ($SystemType -eq "x64") {
        $VMISO = "C:\installer\LiteTouchPE_x64.iso"
    }
    else {
        $VMISO = "C:\installer\LiteTouchPE_x86.iso"
}

# Create REF001
New-VM -Name $VMName -BootDevice CD -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD -Generation $generation -Verbose
New-VHD -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $VMDiskSize -Verbose
Add-VMHardDiskDrive -VMName $VMName -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -Verbose
Set-VMDvdDrive -VMName $VMName -Path $VMISO -Verbose
Set-VM -Name $VMName -ProcessorCount 3
Start-VM -VMName $VMName

#Delete VM after deployment, if it is a reference VM
if ($Reference -eq "Yes") {
    $VM = Get-VM -Name $VMName
    while ($VM.State -ne "off")
    { 
        write-host "The VM is still running"
        sleep 60 
    }
     
    Remove-VM -Name $VMName -Force
    Remove-Item -Recurse -Force $VMLocation\$VMName
}
else {
    Write-Output "VM was created and launched"
}
