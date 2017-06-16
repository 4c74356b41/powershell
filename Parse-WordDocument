$document = ""

$w = New-Object -ComObject word.application
$d = $w.Documents.Open($document)

$d.HyperLinks | ForEach-Object { 
    if ($_.TextToDisplay -notlike "@*") {
        $tempAddress = (Invoke-WebRequest $_.Address -MaximumRedirection 0 -ErrorAction Ignore).Headers.Location
        "<li><a href=`"{0}`">{1}</a>.</li>" -f $tempAddress, $_.TextToDisplay | Out-File c:\result.txt -Append
    }
}

$w.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($w)
Remove-Variable w
