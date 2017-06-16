<#
.Synopsis
   Parse log files to determine total duration of calls.
.DESCRIPTION
   Gets all .log files in the directory specified, finds all 
   strings that match QueryString specified (or uses default
   value of 'A002') and extracts time value from data parsed 
.Parameter LogsPath
   Use this parameter to specify a folder where logs reside
.Parameter QueryString
   Use this parameter to specify what to look after in log files
.Inputs
   String(s)
.Outputs
   To Screen
.EXAMPLE
   Get-CallsDuration -LogsPath "C:\Logs\2016\February"
   Uses path specified to find all .log files and retrives
   total time of calls made. Uses default QueryString of 
   'A002'. Outputs result to screen.
.EXAMPLE
   Get-CallsDuration -LogsPath "C:\Logs\2016\February" -QueryString 'A015'
   Uses path specified to find all .log files and retrives
   total time of calls made. Uses QueryString of 'A015'.
   Outputs result to screen.
#>
function Get-CallsDuration
{
    [CmdletBinding()]
    Param
    (
        # Input Log Folder (Full Path), please 
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$LogsPath,

        # Input Query String, please
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]$QueryString = "A002"
    )

#region Initialize stuff
$files = Get-ChildItem $LogsPath
$result = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))

$RunspaceCollection = @()
$RunspacePool = [RunspaceFactory]::CreateRunspacePool(1,5)
$RunspacePool.Open()

$ScriptBlock = {
    Param($file, $result, $QueryString)
    $content = Get-Content $file.FullName -ReadCount 0
    foreach ($line in $content) {
        if ($line -match "$QueryString") {
        [void]$result.Add($($line -replace ' +',","))
}}}
#endregion

#region Process Data
Foreach ($file in $files) {
	$Powershell = [PowerShell]::Create().AddScript($ScriptBlock).AddArgument($file).AddArgument($result).AddArgument($QueryString)
	$Powershell.RunspacePool = $RunspacePool
	[Collections.Arraylist]$RunspaceCollection += New-Object -TypeName PSObject -Property @{
		Runspace = $PowerShell.BeginInvoke()
		PowerShell = $PowerShell  
}}

While($RunspaceCollection) {
	Foreach ($Runspace in $RunspaceCollection.ToArray()) {
		If ($Runspace.Runspace.IsCompleted) {
			[void]$result.Add($Runspace.PowerShell.EndInvoke($Runspace.Runspace))
			$Runspace.PowerShell.Dispose()
			$RunspaceCollection.Remove($Runspace)
}}}
#endregion

#region Parse Data
$data = ConvertFrom-Csv -InputObject $result -Header "1","2","3","TimeIn","TimeOut","4","5","Dur"
foreach ($line in $data) {
    if ($line.TimeIn -match "$QueryString") { $TimeIn += [timespan]::Parse($line.Dur) }
    else { $TimeOut += [timespan]::Parse($line.Dur) }}
#endregion

Write-Output "IN  Hours: $([math]::Truncate($TimeIn.TotalHours))   Mins: $($TimeIn.Minutes)    Secs: $($TimeIn.Seconds)"
Write-Output "OUT Hours: $([math]::Truncate($TimeOut.TotalHours))  Mins: $($TimeOut.Minutes)   Secs: $($TimeOut.Seconds)"

}
