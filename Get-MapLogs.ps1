$SaveFileDIalog = New-Object System.Windows.Forms.FolderBrowserDialog
$SaveFileDialog.ShowDialog() | Out-Null
if ($SaveFileDialog.SelectedPath -eq $null) {Exit}

$folder = $SaveFileDialog.SelectedPath
New-Item $folder\Parsed -ItemType Directory -ea SilentlyContinue | Out-Null
$regex = "\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}"

Get-ChildItem $folder -Filter *.log | ForEach-Object {
    $content = ([System.IO.File]::ReadAllText($_.FullName) -replace $regex, "$& W3SVC1708439543 DC1-PORTAL1").replace("#Fields: date time", "#Fields: date time s-sitename s-computername")
    [System.IO.File]::WriteAllText("$($folder + "\Parsed\parsed_" + $_.Name)", $content)
}
