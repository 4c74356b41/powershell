function Write-ProgressHelper
{
   param (
        [int]$StepNumber,

        [parameter(Mandatory=$true,HelpMessage="Message",ValueFromPipeline=$true)]
        [string]$Message,

        [parameter(Mandatory=$true,HelpMessage="Title",ValueFromPipeline=$true)]
        [string]$Title
   )
Write-Progress -Status $Message -Activity $Title -PercentComplete (($StepNumber / $steps) * 100)
}

#$script:steps = ([System.Management.Automation.PsParser]::Tokenize((gc "$PSScriptRoot\$($MyInvocation.MyCommand.Name)"), [ref]$null)
#    | where { $_.Type -eq 'Command' -and $_.Content -eq 'Write-ProgressHelper' }).Count

if ($stepCounter) {$stepCounter=$null}

$something = something
$script:steps = $something.Count

$something.foreach({

Write-ProgressHelper -Message '%' -Title '%' -StepNumber ($stepCounter++)
#DoSomething

})
