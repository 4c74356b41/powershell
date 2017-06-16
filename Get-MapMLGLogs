[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
$SaveFileDIalog = New-Object System.Windows.Forms.FolderBrowserDialog
$SaveFileDialog.ShowDialog() | Out-Null
if ($SaveFileDialog.SelectedPath -eq $null) {Exit}

$folder = $SaveFileDialog.SelectedPath
New-Item $folder\Unique -ItemType Directory -ea SilentlyContinue
New-Item $folder\NotUnique -ItemType Directory -ea SilentlyContinue

Get-ChildItem $folder -Filter *.mlg | ForEach-Object {
    $name = $_.Name.Trim(".mlg")
    
    $newcsv = Import-Csv -Path $_.FullName -Encoding Default -Delimiter ";"`
    -Header date,0,user,1,folder,session,2,pc,3,4 | Where-Object {($_.date -like "2015*")`
    -and ($_.session -like "opensession")}

    foreach ($_ in $newcsv) {
        $newcsv[[array]::indexof($newcsv,$_)].pc = $_.pc.split(" ").trim('(m)') | select -Last 1
    }
    $newcsv | Select-Object user,pc -Unique | Export-Csv -Delimiter ";" -NoTypeInformation -Path "$folder\Unique\unique$name.csv" -Encoding Default
    $newcsv | Select-Object date,user,folder,session,pc| Export-Csv -Delimiter ";" -NoTypeInformation -Path "$folder\NotUnique\notunique$name.csv" -Encoding Default
}
