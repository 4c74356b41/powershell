Get-Content "something" | % {
    $td = New-Item -ItemType Directory -Path SomePath\$_
    $Acl = Get-Acl $td.FullName

    # Remove inheritance
    $acl = Get-Acl $td.FullName
    $acl.SetAccessRuleProtection($true,$true)
    Set-Acl $td.FullName $acl

    # Remove ACL
    $acl = Get-Acl $td.FullName
    $acl.Access | %{$acl.RemoveAccessRule($_)} | Out-Null

    # Add local admin
    $permission  = "domain\domain admins","FullControl", "ContainerInherit,ObjectInherit","None","Allow"
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($rule)
    # Add User                
    $permission  = "domain\$_","FullControl", "ContainerInherit,ObjectInherit","None","Allow"
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($rule)

    Set-Acl $td.FullName $acl

    # Needs more testing
    Set-FsrmQuota $td.FullName -Size 5368709120
}
