<#
.Synopsis
This cmdlet parses map\sccm\profiler xml output using Excel com objects, generates a new Excel sheet and writes report data to it

.Description
Can't think of anything

.Parameter FilePath
Path to Excel file for parse

.Parameter Sheet1
MAP sheet name

.Parameter Sheet2
SCCM sheet name

.Parameter Sheet3
Profiler sheet name

.Parameter Sheet4
Report sheet name
#>

Function Parse-ExcelSamReports {
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,HelpMessage="Excel file Path")]
    [String]$FilePath,

    [String]$sheet1 = "map",
    [String]$sheet2 = "sccm",
    [String]$sheet3 = "profiler",
    [String]$sheet4 = "report"
)

# Preparing environment, else Excel won't work via Powershell
if (!(Test-Path "$env:windir\System32\config\systemprofile\Desktop")) {New-Item C:\Windows\System32\config\systemprofile\Desktop -ItemType Directory}
if (!(Test-Path "$env:windir\SysWOW64\config\systemprofile\Desktop")) {New-Item C:\Windows\SysWOW64\config\systemprofile\Desktop -ItemType Directory}

## Opening File, preparing variables, create report sheet
$objExcel = New-Object -ComObject Excel.Application
$wb = $objExcel.Workbooks.Open($FilePath)

$worksheets = $wb.Worksheets
$mapsheet = $Worksheets.Item("$sheet1")
$sccmsheet = $Worksheets.Item("$sheet2")
$profilersheet = $Worksheets.Item("$sheet3")
$reportsheet = $wb.Worksheets.Add()
$reportsheet.Name = "$sheet4"

$mapComputers = @()
$mapWMIcomputers = @()
$sccmComputers = @()
$profilerComputers = @()

## Parse MAP
$findcolumns = $mapsheet.Rows[1] | Select-Object -ExpandProperty value2
for($i=0;$i -le $findcolumns.Length-1;$i++) {
    if ($findcolumns[$i] -like "Computer Name") {$mapcolumn = ++$i}
    if ($findcolumns[$i] -like "WMI Status")    {$mapWMIcolumn = ++$i}
}

for ($i=2; $i -le $mapsheet.UsedRange.Rows.Count; $i++) {
    $mapComputers = $mapComputers + $mapsheet.Cells.Item($i,$mapcolumn).text
    if ($mapsheet.Cells.Item($i,$mapWMIcolumn).text -like "Success") {
        $mapWMIComputers = $mapWMIComputers + $mapsheet.Cells.Item($i,$mapcolumn).text
    }
}

## Parse SCCM
$findcolumns = $sccmsheet.Rows[1] | Select-Object -ExpandProperty value2
for($i=0;$i -le $findcolumns.Length-1;$i++) {
    if ($findcolumns[$i] -like "full name") {$sccmcolumn = ++$i}
}
$sccmComputers = $sccmsheet.Columns[$sccmcolumn] | Select-Object -ExpandProperty value2 | Select-Object -Skip 1

## Parse profiler
$findcolumns = $profilersheet.Rows[1] | Select-Object -ExpandProperty value2
for($i=0;$i -le $findcolumns.Length-1;$i++) {
    if ($findcolumns[$i] -like "full") {$profilercolumn = ++$i}
}
$profilerComputers = $profilersheet.Columns[$profilercolumn] | Select-Object -ExpandProperty value2 | Select-Object -Skip 1

## Comparing...
$wmi = Compare-Object $mapComputers $mapWMIcomputers | Where-Object { $_.SideIndicator -eq '<=' } | select -ExpandProperty inputobject
$map_sccm = Compare-Object $mapComputers $sccmComputers -PassThru
$sccm_profiler = Compare-Object $sccmComputers $profilerComputers -PassThru
$map_missing = $map_sccm | Where-Object {$_.SideIndicator -eq '=>'}
$sccm_missing = $map_sccm | Where-Object {$_.SideIndicator -eq '<='}
$profiler_missing = $sccm_profiler | Where-Object {$_.SideIndicator -eq '<='}

# Reporting
foreach ($_ in $wmi) {
$reportsheet.cells.item(++$wmi.IndexOf($_),1) = "$_"
}
foreach ($_ in $map_missing) {
$reportsheet.cells.item(++$map_missing.IndexOf($_),2) = "$_"
}
foreach ($_ in $sccm_missing) {
$reportsheet.cells.item(++$sccm_missing.IndexOf($_),3) = "$_"
}
foreach ($_ in $profiler_missing) {
$reportsheet.cells.item(++$profiler_missing.IndexOf($_),4) = "$_"
}

$newRow = $reportsheet.Cells.Item(1,1).entireRow
$newRow.Activate() | Out-Null
$newRow.insert("-4121") | Out-Null
$reportsheet.Cells.Item(1,1) = "Bad WMI"
$reportsheet.Cells.Item(1,2) = "Missing in MAP"
$reportsheet.Cells.Item(1,3) = "Missing in SCCM"
$reportsheet.Cells.Item(1,4) = "Missing in Profiler"
$reportsheet.Rows.Item(1).Font.Size = 18
$reportsheet.Rows.Item(1).Font.Bold = $True
$reportsheet.Rows.Item(1).HorizontalAlignment = -4108
$reportsheet.Rows.Item(1).Font.Color = 8210719
$reportsheet.Rows.Item(1).Interior.ColorIndex = 48
$reportsheet.Columns.Item(1).columnwidth = 30
$reportsheet.Columns.Item(2).columnwidth = 30
$reportsheet.Columns.Item(3).columnwidth = 30
$reportsheet.Columns.Item(4).columnwidth = 30

$wb.Save()
$objExcel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($objExcel)
[gc]::collect() | Out-Null
[gc]::WaitForPendingFinalizers() | Out-Null
Remove-Variable $wb
Remove-Variable $objExcel
}
