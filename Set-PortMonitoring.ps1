$ins = Get-SCOMClassInstance | ? {$_.displayname -like “PORT-*”}
foreach ($i in $ins) {get-scomtask | ?{($_.Target.Identifier.Path -like “System.NetworkManagement.NetworkAdapter”)
  -and ($_.DisplayName -like “Enable Port*”)} | Start-SCOMTask -Instance $i}
