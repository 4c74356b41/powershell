#Cast Variables:
$strName = $env:username
$FolderLocation = $Env:appdata + '\Microsoft\sgn'
mkdir $FolderLocation -force -ea 0
$time = Get-Date

$i = 1,2,4,5
foreach ($_ in $i) {
    $path = "HKCU:\Software\Microsoft\Office\1" + $_ + ".0\Common\General"
    if (test-path $path) {New-ItemProperty -Path $path -Name Signatures -value sgn -propertytype string -force}
}

#Query Active Directory
$strFilter = "(&(objectCategory=User)(samAccountName=$strName))"
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.Filter = $strFilter
$objPath = $objSearcher.FindOne()
$objUser = $objPath.GetDirectoryEntry()

$strName = $objUser.FullName
$strTitle = $objUser.Title
$strCompany = $objUser.Company
$strCred = $objUser.info
$strStreet = $objUser.StreetAddress
$strPhone = $objUser.telephoneNumber
$strCity =  $objUser.l
$strPostCode = $objUser.PostalCode
$strCountry = $objUser.co
$strEmail = $objUser.mail
$strWebsite = $objUser.wWWHomePage
$strdepartment = $objUser.Department

$mask = $strName + $strTitle[0] + $strPhone + $strEmail + $strdepartment
$key = Get-Content "$FolderLocation\mask.txt" -ea 0

$repeat = {
#Create "mask" file
$mask | Out-File $FolderLocation\mask.txt -Encoding UTF8
#Write data to file
$stream = [System.IO.StreamWriter] "$FolderLocation\$strName.htm"
$stream.WriteLine("<!DOCTYPE HTML PUBLIC `"-//W3C//DTD HTML 4.0 Transitional//EN`">")
$stream.WriteLine("<HTML><HEAD><TITLE>Signature</TITLE>")
$stream.WriteLine("<META http-equiv=Content-Type content=`"text/html; charset=UTF-8`">")
$stream.WriteLine("<BODY>")
$stream.WriteLine("<SPAN style=`"FONT-SIZE: 10pt; COLOR: black; FONT-FAMILY: `'Trebuchet MS`'`">")
$stream.WriteLine("<BR><BR>")
$stream.WriteLine("<B><SPAN style=`"FONT-SIZE: 9pt; COLOR: gray; FONT-FAMILY: `'Trebuchet MS`'`">" + $strName + "</SPAN></B><BR>")
$stream.WriteLine("<SPAN style=`"FONT-SIZE: 9pt; COLOR: gray; FONT-FAMILY: `'Trebuchet MS`'`">" + $strTitle[0] + "<BR> $strdepartment")
$stream.WriteLine("</SPAN><BR>")
$stream.WriteLine("<SPAN style=`"FONT-SIZE: 9pt; COLOR: gray; FONT-FAMILY: `'Trebuchet MS`'`">")
$stream.WriteLine("<B><SPAN style=`"FONT-SIZE: 9pt; COLOR: gray; FONT-FAMILY: `'Trebuchet MS`'`">ООО ИК &#171СИБИНТЕК&#187</SPAN></B>" )
$stream.WriteLine("<BR><SPAN style=`"FONT-SIZE: 9pt; COLOR: gray; FONT-FAMILY: `'Trebuchet MS`'`">Тел.: +7-495-755-5273 доб. " + $strPhone)
$stream.WriteLine("<BR><A href=`"mailto:"+ $strEmail +"`"><SPAN title=" + $strEmail + " style=`"COLOR: gray; TEXT-DECORATION: none; text-underline: none; FONT-FAMILY: `'Trebuchet MS`'`">" + $strEmail[0] + "</SPAN></A>")
$stream.WriteLine("<SPAN style=`"FONT-SIZE: 9pt; COLOR: gray; FONT-FAMILY: `'Trebuchet MS`'`"></SPAN>")
$stream.WriteLine("<BR><A href='http://sibintek.ru'>http://sibintek.ru</A>")
$stream.WriteLine("</BODY>")
$stream.WriteLine("</HTML>")
$stream.close()

#Open HTM Signature File 
$MSWord = New-Object -com word.application 
$fullPath = $FolderLocation+'\'+$strName+'.htm' 
$MSWord.Documents.Open($fullPath)
#Save HTM Signature File as RTF 
$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatRTF"); 
$path = $FolderLocation+'\'+$strName+".rtf" 
$MSWord.ActiveDocument.SaveAs([ref] $path, [ref]$saveFormat)
#Close File 
$MSWord.ActiveDocument.Close() 
#Forcing signature for new messages 
$EmailOptions = $MSWord.EmailOptions 
$EmailSignature = $EmailOptions.EmailSignature 
$EmailSignatureEntries = $EmailSignature.EmailSignatureEntries 
$EmailSignature.NewMessageSignature=$StrName 
#Forcing signature for reply/forward messages 
$EmailSignature.ReplyMessageSignature=$StrName 

Stop-Process -Name winword -Force
Stop-Process -Name outlook -Force
}

If (Test-Path "$FolderLocation\mask.txt") {
$compare = Compare-Object -ReferenceObject $mask -DifferenceObject $key -SyncWindow 0
    if ($compare -ne $null) {
        &$repeat
    }
} Else {&$repeat}
