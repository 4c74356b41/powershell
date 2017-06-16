<#
.Synopsis
Copies file to a VM.

.Description
Copies file to a VM.
Requires running and up to date guest integration services on target VM. I always keep messing this up, so i created this ;)

.Parameter VMName
Pick a VM where to copy file

.Parameter SourcePath
Pick a file you want to copy to a VM

.Parameter DestinationPath
Where do we put this file on a VM

#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,HelpMessage="To what VM should we copy file")]
    [String]$VMName,

    [Parameter(Mandatory=$True,HelpMessage="Pick a file you want to copy to a VM")]
    [String]$SourcePath,

    [Parameter(Mandatory=$True,HelpMessage="Where do we put this file on a VM?")]
    [String]$DestinationPath,

    [String]$FileSource = "Host"
)

# Copy File to VM
Copy-VMFile $VMName -SourcePath $SourcePath -DestinationPath $DestinationPath -CreateFullPath -Force -FileSource $FileSource
