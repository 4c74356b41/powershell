Import-Module ActiveDirectory
Get-Content something | % {
        $time = 0
        $tmp = Get-ADUser -Filter * | ? {$_.samaccountname -like "$user"} | Get-ADObject -Properties lastlogon
        if($tmp.lastLogon -gt $time) 
            {
              $time = $tmp.lastLogon
            }
        $dt = [DateTime]::FromFileTime($time)
        Write-Output "$user $dt"
}
