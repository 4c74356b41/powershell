Unregister-Event -SourceIdentifier volumeChange
Register-WmiEvent -Class win32_VolumeChangeEvent -SourceIdentifier volumeChange

do{
 $newEvent = Wait-Event -SourceIdentifier volumeChange
 $eventType = $newEvent.SourceEventArgs.NewEvent.EventType
 $eventTypeName = switch($eventType)
{
 1 {"Configuration changed"}
 2 {"Device arrival"}
 3 {"Device removal"}
 4 {"docking"}
}

 if ($eventType -eq 2){
 $driveLetter = $newEvent.SourceEventArgs.NewEvent.DriveName
 $driveLabel = ([wmi]"Win32_LogicalDisk='$driveLetter'").VolumeName
 net use \\xxx\x$ xxx /user:xxx\xxx /persistent:no
 Get-ChildItem –path $driveLetter -Recurse |
 Foreach-Object { copy-item -Path $_.fullname -Destination \\xxx\x$}
}
 Remove-Event -SourceIdentifier volumeChange
} while (1 -eq 1) #Loop until next event

Unregister-Event -SourceIdentifier volumeChange
