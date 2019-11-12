#Loads Active Directory Authentication Library
function Load-ActiveDirectoryAuthenticationLibrary(){
    $moduleDirPath = [Environment]::GetFolderPath("MyDocuments") + "\WindowsPowerShell\Modules"
    $modulePath = $moduleDirPath + "\AADGraph"

    if(-not (Test-Path ($modulePath+"\Nugets"))) {New-Item -Path ($modulePath+"\Nugets") -ItemType "Directory" | out-null}
    $adalPackageDirectories = (Get-ChildItem -Path ($modulePath+"\Nugets") -Filter "Microsoft.IdentityModel.Clients.ActiveDirectory*" -Directory)

    if($adalPackageDirectories.Length -eq 0){
        Write-Host "Active Directory Authentication Library Nuget doesn't exist. Downloading now ..." -ForegroundColor Yellow
        if(-not(Test-Path ($modulePath + "\Nugets\nuget.exe")))
        {
            Write-Host "nuget.exe not found. Downloading from http://www.nuget.org/nuget.exe ..." -ForegroundColor Yellow
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile("http://www.nuget.org/nuget.exe",$modulePath + "\Nugets\nuget.exe");
        }
        $nugetDownloadExpression = $modulePath + "\Nugets\nuget.exe install Microsoft.IdentityModel.Clients.ActiveDirectory -Version 2.14.201151115 -OutputDirectory " + $modulePath + "\Nugets | out-null"
        Invoke-Expression $nugetDownloadExpression
    }

    $adalPackageDirectories = (Get-ChildItem -Path ($modulePath+"\Nugets") -Filter "Microsoft.IdentityModel.Clients.ActiveDirectory*" -Directory)
    $ADAL_Assembly = (Get-ChildItem "Microsoft.IdentityModel.Clients.ActiveDirectory.dll" -Path $adalPackageDirectories[$adalPackageDirectories.length-1].FullName -Recurse)
    $ADAL_WindowsForms_Assembly = (Get-ChildItem "Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll" -Path $adalPackageDirectories[$adalPackageDirectories.length-1].FullName -Recurse)
    if($ADAL_Assembly.Length -gt 0 -and $ADAL_WindowsForms_Assembly.Length -gt 0){
        Write-Host "Loading ADAL Assemblies ..." -ForegroundColor Green
        [System.Reflection.Assembly]::LoadFrom($ADAL_Assembly[0].FullName) | out-null
        [System.Reflection.Assembly]::LoadFrom($ADAL_WindowsForms_Assembly.FullName) | out-null
        return $true
    }
    else{
        Write-Host "Fixing Active Directory Authentication Library package directories ..." -ForegroundColor Yellow
        $adalPackageDirectories | Remove-Item -Recurse -Force | Out-Null
        Write-Host "Not able to load ADAL assembly. Delete the Nugets folder under" $modulePath ", restart PowerShell session and try again ..."
        return $false
    }
}

#Acquire AAD token

function AcquireToken($clientID, $redirectUri, $resourceAppIdURI, $authority, $mfa)
{
    
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority,$false


    if($mfa)
    {
        $authResult = $authContext.AcquireToken($resourceAppIdURI,$ClientID,$redirectUri,[Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Auto, [Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier]::AnyUser, "amr_values=mfa")
        Set-Variable -Name mfaDone -Value $true -Scope Global
    }
    else
    {
        $authResult = $authContext.AcquireToken($resourceAppIdURI,$ClientID,$redirectUri,[Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Always)
    }
    

    if($authResult -ne $null)
    {
        Write-Host "User logged in successfully ..." -ForegroundColor Green
    }
    Set-Variable -Name headerParams -Value @{'Authorization'="$($authResult.AccessTokenType) $($authResult.AccessToken)"} -Scope Global
    Set-Variable -Name assigneeId -Value $authResult.UserInfo.UniqueId -Scope Global
}

#Gets my jit assignments
function MyJitAssignments(){
    $urlme = $global:MSGraphRoot + "me/"
    $response = Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $urlme -Method Get
    $me = ConvertFrom-Json $response.Content
    $subjectId = $me.id
    Write-Host $subjectId

    $url = $serviceRoot + "roleAssignments?`$expand=linkedEligibleRoleAssignment,subject,roleDefinition(`$expand=resource)&`$filter=(assignmentState+eq+'Eligible')+and+(subjectId+eq+'" + $subjectId + "')" 

    Write-Host $url
    $response = Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url -Method Get
    $assignments = ConvertFrom-Json $response.Content
    Write-Host ""
    Write-Host "Role assignments..." -ForegroundColor Green
    $i = 0
    $obj = @()
    foreach ($assignment in $assignments.value)
    {
        $item = New-Object psobject -Property @{
        id = ++$i
        IdGuid =  $assignment.id
        ResourceId =  $assignment.roleDefinition.resource.id
        OriginalId =  $assignment.roleDefinition.resource.externalId
        ResourceName =  $assignment.roleDefinition.resource.displayName
        ResourceType =  $assignment.roleDefinition.resource.type
        RoleId = $assignment.roleDefinition.id
        RoleName = $assignment.roleDefinition.displayName
        ExpirationDate = $assignment.endDateTime
        SubjectId = $assignment.subject.id
    }
    $obj = $obj + $item
    }

    return $obj
}


#List resources
function ListResources(){
    $url = $serviceRoot + "resources?`$filter=(type+eq+'subscription')" 
     Write-Host $url

    $response = Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url -Method Get
    $resources = ConvertFrom-Json $response.Content
    $i = 0
    $obj = @()
    foreach ($resource in $resources.value)
    {
        $item = New-Object psobject -Property @{
        id = ++$i
        ResourceId =  $resource.id
        ResourceName =  $resource.DisplayName
        Type =  $resource.type
        ExternalId =  $resource.externalId
    }
    $obj = $obj + $item
}

return $obj
}

#List roles
function ListRoles($resourceId){
    $url = $serviceRoot + "resources/" + $resourceId + "/roleDefinitions?&`$orderby=displayName"
    Write-Host $url

    $response = Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url -Method Get
    $roles = ConvertFrom-Json $response.Content
    $i = 0
    $obj = @()
    foreach ($role in $roles.value)
    {
        $item = New-Object psobject -Property @{
        id = ++$i
        RoleDefinitionId =  $role.id
        RoleName =  $role.DisplayName
    }
    $obj = $obj + $item
    }

    return $obj
}


#List roles
function ListRoleSettings($resourceId){
    $url = $serviceRoot + "resources/" + $resourceId + "/roleSettings?&`$expand=resource,roleDefinition&`$orderby=lastUpdatedDateTime+desc"
    Write-Host $url

    
    $response = Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url -Method Get
    $roleSettings = ConvertFrom-Json -InputObject $response.Content
        
    $i = 0
    $obj = @()
    foreach ($roleSetting in $roleSettings.value)
    {
        # userMemberSettings
        $UMSExp = ""
        $UMSMFA = ""
        $UMSJus = ""
        $UMSActDay = ""
        $UMSApprov = ""
        $UMSTicket = ""

        foreach ($UMS in $roleSetting.userMemberSettings)
        {

            switch ($UMS.ruleIdentifier) {
               "MfaRule" 
                        {
                            $UMSMFA = $UMS.setting
                            break
                        }
               "ExpirationRule" 
                        {
                            $UMSExp = $UMS.setting
                            break
                        }
                "JustificationRule"
                        {
                            $UMSJus = $UMS.setting
                            break
                        }
                "ActivationDayRule"
                        {
                            $UMSActDay = $UMS.setting
                            break
                        }
                "ApprovalRule"
                        {
                            $UMSApprov = $UMS.setting
                            break
                        }
                "TicketingRule"
                        {
                            $UMSTicket = $UMS.setting
                            break
                        }
            }
        }
        
        # AdminEligibleSettings
        $AESExp = ""
        $AESMFA = ""
        $AESJus = ""
        $AESActDay = ""
        $AESApprov = ""
        $AESTicket = ""

        foreach ($AES in $roleSetting.adminEligibleSettings)
        {

            switch ($AES.ruleIdentifier) {
               "MfaRule" 
                        {
                            $AESMFA = $AES.setting
                            break
                        }
               "ExpirationRule" 
                        {
                            $AESExp = $AES.setting
                            break
                        }
                "JustificationRule"
                        {
                            $AESJus = $AES.setting
                            break
                        }
                "ActivationDayRule"
                        {
                            $AESActDay = $AES.setting
                            break
                        }
                "ApprovalRule"
                        {
                            $AESApprov = $AES.setting
                            break
                        }
                "TicketingRule"
                        {
                            $AESTicket = $AES.setting
                            break
                        }
            }
        }

        # AdminMemberSettings
        $AMSExp = ""
        $AMSMFA = ""
        $AMSJus = ""
        $AMSActDay = ""
        $AMSApprov = ""
        $AMSTicket = ""

        foreach ($AMS in $roleSetting.adminMemberSettings)
        {

            switch ($AMS.ruleIdentifier) {
               "MfaRule" 
                        {
                            $AMSMFA = $AMS.setting
                            break
                        }
               "ExpirationRule" 
                        {
                            $AMSExp = $AMS.setting
                            break
                        }
                "JustificationRule"
                        {
                            $AMSJus = $AMS.setting
                            break
                        }
                "ActivationDayRule"
                        {
                            $AMSActDay = $AMS.setting
                            break
                        }
                "ApprovalRule"
                        {
                            $AMSApprov = $AMS.setting
                            break
                        }
                "TicketingRule"
                        {
                            $AMSTicket = $AMS.setting
                            break
                        }
            }
        }

        $item = New-Object psobject -Property @{
            id = ++$i
            RoleSettingId = $roleSetting.id
            ResourceId = $roleSetting.resourceId
            ResourceName = $roleSetting.resource.displayName
            RoleDefinitionId = $roleSetting.roleDefinitionId
            RoleName = $roleSetting.roleDefinition.displayName
            AdminMemberSettings = $roleSetting.adminMemberSettings
            AdminEligibleSettings = $roleSetting.adminEligibleSettings
            UserEligibleSettings = $roleSetting.userEligibleSettings
            UserMemberSettings = $roleSetting.userMemberSettings
               
            UserMemberSettingsMfaRule = $UMSMFA
            UserMemberSettingsExpirationRule = $UMSExp
            UserMemberSettingsJustificationRule = $UMSJus
            UserMemberSettingsActivationDayRule = $UMSActDay
            UserMemberSettingsApprovalRule = $UMSApprov
            UserMemberSettingsTicketingRule = $UMSTicket

            AdminEligibleSettingsMfaRule = $AESMFA
            AdminEligibleSettingsExpirationRule = $AESExp
            AdminEligibleSettingsJustificationRule = $AESJus
            AdminEligibleSettingsActivationDayRule = $AESActDay
            AdminEligibleSettingsApprovalRule = $AESApprov
            AdminEligibleSettingsTicketingRule = $AESTicket

            AdminMemberSettingsMfaRule = $AMSMFA
            AdminMemberSettingsExpirationRule = $AMSExp
            AdminMemberSettingsJustificationRule = $AMSJus
            AdminMemberSettingsActivationDayRule = $AMSActDay
            AdminMemberSettingsApprovalRule = $AMSApprov
            AdminMemberSettingsTicketingRule = $AMSTicket
        }

         
        
        $obj = $obj + $item
    }

    return $obj
}

#List Assignment
function ListAssignmentsWithFilter($resourceId, $roleDefinitionId){
    $url = $serviceRoot + "resources/" + $resourceId + "`/roleAssignments?`$expand=subject,roleDefinition(`$expand=resource)&`$filter=(roleDefinition/id+eq+'" + $roleDefinitionId + "')"
    Write-Host $url

    $response = Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url -Method Get
    $roleAssignments = ConvertFrom-Json $response.Content
    $i = 0
    $obj = @()
    foreach ($roleAssignment in $roleAssignments.value)
        {
        $item = New-Object psobject -Property @{
        id = ++$i
        RoleAssignmentId =  $roleAssignment.id
        ResourceId =  $roleAssignment.roleDefinition.resource.id
        OriginalId =  $roleAssignment.roleDefinition.resource.externalId
        ResourceName =  $roleAssignment.roleDefinition.resource.displayName
        ResourceType =  $roleAssignment.roleDefinition.resource.type
        RoleId = $roleAssignment.roleDefinition.id
        RoleName = $roleAssignment.roleDefinition.displayName
        ExpirationDate = $roleAssignment.endDateTime
        SubjectId = $roleAssignment.subject.id
        UserName = $roleAssignment.subject.displayName
        AssignmentState = $roleAssignment.AssignmentState
    }
    $obj = $obj + $item
}

return $obj
}


#List Assignment
function ListExpiringEligibleAssignmentsWithFilter($resourceId){
    $url = $serviceRoot + "resources/" + $resourceId + "`/roleAssignments?`$expand=subject,roleDefinition(`$expand=resource)&`$filter=(assignmentState+eq+'Eligible')"
   
    Write-Host $url

    $response = Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url -Method Get
    $roleAssignments = ConvertFrom-Json $response.Content
    $i = 0
    $obj = @()
 $expiration = (Get-Date).ToUniversalTime().AddDays(14)
    foreach ($roleAssignment in $roleAssignments.value)
    {
        if(($roleAssignment.endDateTime -ne $null) -and ([DateTime]$roleAssignment.endDateTime -lt $expiration))
        {
            $item = New-Object psobject -Property @{
                id = ++$i
                RoleAssignmentId =  $roleAssignment.id
                ResourceId =  $roleAssignment.roleDefinition.resource.id
                OriginalId =  $roleAssignment.roleDefinition.resource.externalId
                ResourceName =  $roleAssignment.roleDefinition.resource.displayName
                ResourceType =  $roleAssignment.roleDefinition.resource.type
                RoleId = $roleAssignment.roleDefinition.id
                RoleName = $roleAssignment.roleDefinition.displayName
                ExpirationDate = $roleAssignment.endDateTime
                SubjectId = $roleAssignment.subject.id
                UserName = $roleAssignment.subject.displayName
                AssignmentState = $roleAssignment.AssignmentState
            }
            $obj = $obj + $item
        }
        
    }

    return $obj
}

#List Users
function ListUsers($user_search){
    $url = $MSGraphRoot + "users?`$filter=startswith(displayName,'" + $user_search + "')"
    Write-Host $url

    $response = Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url -Method Get
    $users = ConvertFrom-Json $response.Content
    $i = 0
    $obj = @()
    foreach ($user in $users.value)
    {
        $item = New-Object psobject -Property @{
        id = ++$i
        UserId =  $user.id
        UserName =  $user.DisplayName
    }
    $obj = $obj + $item
    }

    return $obj
}

#Activates the user
function Activate($isRecursive = $false){
    if($isRecursive -eq $false)
    {
        $assignments = MyJitAssignments
        $assignments | Format-Table -AutoSize -Wrap id,RoleName,ResourceName,ResourceType,ExpirationDate
        $choice = Read-Host "Enter Id to activate"
        [int]$hours = Read-Host "Enter Activation duration in hours"
        $reason = Read-Host "Enter Reason"
    }

    $id = $assignments[$choice-1].IdGuid
    $resourceId = $assignments[$choice-1].ResourceId
    $roleDefinitionId = $assignments[$choice-1].RoleId
    $subjectId = $assignments[$choice-1].SubjectId
    $url = $serviceRoot + "roleAssignmentRequests"
    $postParams = '{"id":"00000000-0000-0000-0000-000000000000","assignmentState":"Active","type":"UserAdd","reason":"' + $reason + '","roleDefinitionId":"' + $roleDefinitionId + '","resourceId":"' + $resourceId + '","subjectId":"' + $subjectId + '","schedule":{"duration":"PT' + $hours + 'H","startDateTime":"' + (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ") + '","type":"Once"},"linkedEligibleRoleAssignmentId":"' + $id + '"}'
    write-Host $postParams

    try
    {
        $response = Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url -Method Post -ContentType "application/json" -Body $postParams
        Write-Host "Activation request queued successfully ..." -ForegroundColor Green
        $recursive = $false
    }
    catch
    {
        $stream = $_.Exception.Response.GetResponseStream()
        $stream.Position = 0;
        $streamReader = New-Object System.IO.StreamReader($stream)
        $err = $streamReader.ReadToEnd()
        $streamReader.Close()
        $stream.Close()

        if($mfaDone -eq $false -and $err.Contains("MfaRule"))
        {
            Write-Host "Prompting the user for mfa ..." -ForegroundColor Green
            AcquireToken $global:clientID $global:redirectUri $global:resourceAppIdURI $global:authority $true
            Activate $true
        }
        else
        {
            Write-Host $err -ForegroundColor Red
        }
    }
}


#Extend the user role assignment
function ExtendRoleAssignment($roleAssignment, $hours){

    $url = $serviceRoot + "roleAssignmentRequests"
    $postParams = '{"id":"00000000-0000-0000-0000-000000000000","assignmentState":"Eligible","type":"AdminExtend","reason":"bulk extend","roleDefinitionId":"' + $roleAssignment.RoleId + '","resourceId":"' + $roleAssignment.ResourceId + '","subjectId":"' + $roleAssignment.SubjectId + '","schedule":{"duration":"PT' + $hours + 'H","startDateTime":"' + (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ") + '","type":"Once"}}'
    write-Host $postParams

    try
    {
        $response = Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url -Method Post -ContentType "application/json" -Body $postParams
        Write-Host "Extend Successfully ..." -ForegroundColor Green
        $recursive = $false
    }
    catch
    {
        $stream = $_.Exception.Response.GetResponseStream()
        $stream.Position = 0;
        $streamReader = New-Object System.IO.StreamReader($stream)
        $err = $streamReader.ReadToEnd()
        $streamReader.Close()
        $stream.Close()
    }
}

#Delete the user role assignment
function DeleteRoleAssignment($roleAssignment){

    $resourceId = $roleAssignments[$ra_choice-1].ResourceId
    $roleDefinitionId = $roleAssignments[$ra_choice-1].RoleId
    $subjectId = $roleAssignments[$ra_choice-1].SubjectId
    $assignmentState = $roleAssignments[$ra_choice-1].AssignmentState

    # Delete the chosen member
    $url = $serviceRoot + "roleAssignmentRequests"
    $postParams = '{"assignmentState":"' + $assignmentState + '","type":"AdminRemove","reason":"Assign","roleDefinitionId":"' + $roleDefinitionId + '","resourceId":"' + $resourceId + '","subjectId":"' + $subjectId + '"}'
    
    write-Host $postParams
    write-Host $url
    try
    {
        $response = Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url -Method Post -ContentType "application/json" -Body $postParams
        Write-Host "Assignment has been deleted" -ForegroundColor Green
        $recursive = $false
    }
    catch
    {
        $stream = $_.Exception.Response.GetResponseStream()
        $stream.Position = 0;
        $streamReader = New-Object System.IO.StreamReader($stream)
        $err = $streamReader.ReadToEnd()
        $streamReader.Close()
        $stream.Close()
        
        Write-Host $err -ForegroundColor Red
        
    }
}


#Deactivates the user
function Deactivate($isRecursive = $false){
    if($isRecursive -eq $false)
    {
        $assignments = MyJitAssignments
        $assignments | Format-Table -AutoSize -Wrap id,RoleName,ResourceName,ResourceType,ExpirationDate
        $choice = Read-Host "Enter Id to deactivate"
    }

    $id = $assignments[$choice-1].IdGuid
    $resourceId = $assignments[$choice-1].ResourceId
    $roleDefinitionId = $assignments[$choice-1].RoleId
    $subjectId = $assignments[$choice-1].SubjectId
    $url = $serviceRoot + "roleAssignmentRequests"
    $postParams = '{"assignmentState":"Active","type":"UserRemove","roleDefinitionId":"' + $roleDefinitionId + '","resourceId":"' + $resourceId + '","subjectId":"' + $subjectId + '"}'
    $response = Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url -Method Post -ContentType "application/json" -Body $postParams
    Write-Host "Role deactivated successfully ..." -ForegroundColor Green
    $recursive = $false
}

#Patch RoleSetting
function PatchRoleSetting($patchParams, $roleSettingId){

    $url = $serviceRoot + "roleSettings/" + $roleSettingId
    Write-Host $url
    Write-Host $patchParams

    try
    {
        $response = Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url -Method Patch -ContentType "application/json" -Body $patchParams
        Write-Host "Update RoleSetting successfully ..." -ForegroundColor Green
        $recursive = $false
    }
    catch
    {
        $stream = $_.Exception.Response.GetResponseStream()
        $stream.Position = 0;
        $streamReader = New-Object System.IO.StreamReader($stream)
        $err = $streamReader.ReadToEnd()
        $streamReader.Close()
        $stream.Close()
    }
}

#List RoleAssignment
function ListAssignment(){
    #List and Pick resource
    $resources = ListResources
    $resources | Format-Table -AutoSize -Wrap id, ResourceName, Type, ExternalId
    $res_choice = Read-Host "Pick an resource Id for assigment"
    $resourceId = $resources[$res_choice-1].ResourceId

    #List and Pick a role
    $roles = ListRoles($resourceId)
    $roles | Format-Table -AutoSize -Wrap id, RoleName, RoleDefinitionId
    $role_choice = Read-Host "Pick a role Id"
    $roleDefinitionId = $roles[$role_choice-1].RoleDefinitionId
    write-Host $roleDefinitionId

    #List Member
    $roleAssignments = ListAssignmentsWithFilter $resourceId $roleDefinitionId
    $roleAssignments | Format-Table -AutoSize -Wrap id, ResourceName, ResourceType, RoleName, UserName, AssignmentState, ExpirationDate
}


#Delete RoleAssignment
function DelAssignment(){
    #List and Pick resource
    $resources = ListResources
    $resources | Format-Table -AutoSize -Wrap id, ResourceName, Type, ExternalId
    $res_choice = Read-Host "Pick an resource Id for assigment"
    $resourceId = $resources[$res_choice-1].ResourceId

    #List and Pick a role
    $roles = ListRoles($resourceId)
    $roles | Format-Table -AutoSize -Wrap id, RoleName, RoleDefinitionId
    $role_choice = Read-Host "Pick a role Id"
    $roleDefinitionId = $roles[$role_choice-1].RoleDefinitionId
    write-Host $roleDefinitionId

    #List Member
    $roleAssignments = ListAssignmentsWithFilter $resourceId $roleDefinitionId
    $roleAssignments | Format-Table -AutoSize -Wrap id, ResourceName, ResourceType, RoleName, UserName, AssignmentState, ExpirationDate
    
    $ra_choice = Read-Host "Pick a roleAssignment you want to delete, Pick 0 for Del All active, and Pick -1 to exit"

    if ($ra_choice -eq -1)
    {
        return
    }

    if (($roleAssignments -eq $null) -or ($roleAssignments[$ra_choice-1] -eq $null))
    {
        Write-Host "Number out-of range"
        return
    }

    if ($ra_choice -gt 0)
    {
        DeleteRoleAssignment $roleAssignments[$ra_choice-1]

    } elseif  ($ra_choice -eq 0)
    {
        foreach ($ra in $roleAssignments)
        {
            if ($ra.AssignmentState -eq "Active") 
            {
                DeleteRoleAssignment $ra
            }            
        }
    }

}


#List ExpiringRoleAssignment
function ListExpiringEligibleAssignments(){
    #List and Pick resource
    $resources = ListResources
    $resources | Format-Table -AutoSize -Wrap id, ResourceName, Type, ExternalId
    $res_choice = Read-Host "Pick a resource Id for assigment"
    $resourceId = $resources[$res_choice-1].ResourceId

    #List Expiring Member of the target resource
    $roleAssignments = ListExpiringEligibleAssignmentsWithFilter $resourceId
    $roleAssignments | Format-Table -AutoSize -Wrap id, ResourceName, ResourceType, RoleName, UserName, AssignmentState, ExpirationDate
    

    if ($roleAssignments -eq $null)
    {
        Write-Host "No Eligible memberships are expiring" -ForegroundColor Green
    } else
    {
        $ra_choice = Read-Host "Pick a roleAssignment you want to extend, Pick 0 for ExtendAll, and Pick -1 to exit"

        if ($ra_choice -eq -1)
        {
            return
        }

        $days = Read-Host "Pick number of days, you want to extends"
        $hours = [int]$days * 24
        Write-Host $hours

        if ($ra_choice -gt 0)
        {
            ExtendRoleAssignment $roleAssignments[$ra_choice-1] $hours

        } elseif  ($ra_choice -eq 0)
        {
            foreach ($ra in $roleAssignments)
            {
                ExtendRoleAssignment $ra $hours                
            }
        }
    }
}


#Assign a user to Eligible
function AssignmentEligible() {
    #List and Pick resource
    $resources = ListResources
    $resources | Format-Table -AutoSize -Wrap id, ResourceName, Type, ExternalId
    $res_choice = Read-Host "Pick an resource Id for assigment"
    $resourceId = $resources[$res_choice-1].ResourceId

    #List and Pick a role
    $roles = ListRoles($resourceId)
    $roles | Format-Table -AutoSize -Wrap id, RoleName, RoleDefinitionId
    $role_choice = Read-Host "Pick a role Id"
    $roleDefinitionId = $roles[$role_choice-1].RoleDefinitionId
    write-Host $roleDefinitionId

    #Search user by Name, and pick a user
    $user_search = Read-Host "user Name start with..."
    $users = ListUsers($user_search)
    $users | Format-Table -AutoSize -Wrap id, UserName, UserId
    $user_choice = Read-Host "Pick a user Id"
    
    if (($users -eq $null) -or ($users[$user_choice-1] -eq $null))
    {
        Write-Host "Number out-of range"
        return
    }

    $subjectId = $users[$user_choice-1].UserId

    $url = $serviceRoot + "roleAssignmentRequests"
    # Update end time
    $ts = New-TimeSpan -Days 30
    $postParams = '{"assignmentState":"Eligible","type":"AdminAdd","reason":"Assign","roleDefinitionId":"' + $roleDefinitionId + '","resourceId":"' + $resourceId + '","subjectId":"' + $subjectId + '","schedule":{"startDateTime":"' + (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ") + '","endDateTime":"' + ((Get-Date) + $ts).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ") + '","type":"Once"}}'
    write-Host $postParams

    try
    {
        $response = Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url -Method Post -ContentType "application/json" -Body $postParams
        Write-Host "Assignment request queued successfully ..." -ForegroundColor Green
        $recursive = $false
    }
    catch
    {
        $stream = $_.Exception.Response.GetResponseStream()
        $stream.Position = 0;
        $streamReader = New-Object System.IO.StreamReader($stream)
        $err = $streamReader.ReadToEnd()
        $streamReader.Close()
        $stream.Close()

        if($mfaDone -eq $false -and $err.Contains("MfaRule"))
        {
            Write-Host "Prompting the user for mfa ..." -ForegroundColor Green
            AcquireToken $global:clientID $global:redirectUri $global:resourceAppIdURI $global:authority $true
            Activate $true
        }
        else
        {
            Write-Host $err -ForegroundColor Red
        }
    }
}


#Cancel Request
    function CancelRequest() {
    $requestId = Read-Host "RequestId"
    $url = $serviceRoot + "roleAssignmentRequests/" + $requestId + "/cancel" 
    write-Host $url

    try
    {
        $response = Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url -Method Post -ContentType "application/json"
        Write-Host "Cancel request queued successfully ..." -ForegroundColor Green
        $recursive = $false
    }
    catch
    {
        $stream = $_.Exception.Response.GetResponseStream()
        $stream.Position = 0;
        $streamReader = New-Object System.IO.StreamReader($stream)
        $err = $streamReader.ReadToEnd()
        $streamReader.Close()
        $stream.Close()
        Write-host $err 
    }
}


#List RoleSetting
function ListRoleSetting(){
    #List and Pick resource
    $resources = ListResources
    $resources | Format-Table -AutoSize -Wrap id, ResourceName, Type, ExternalId
    $res_choice = Read-Host "Pick an resource Id for assigment"
    $resourceId = $resources[$res_choice-1].ResourceId

    #List RoleSettings and Pick a role/multiple role to update
    $roleSettings = ListRoleSettings($resourceId)
    $roleSettings | Format-List id, RoleName, RoleDefinitionId, ResourceName, ResourceId, AdminMemberSettings, AdminEligibleSettings, UserMemberSettings, UserEligibleSettings,
    AdminMemberSettingsMfaRule, AdminMemberSettingsExpirationRule, AdminMemberSettingsJustificationRule, AdminMemberSettingsActivationDayRule, AdminMemberSettingsApprovalRule, AdminMemberSettingsTicketingRule,
    AdminEligibleSettingsMfaRule, AdminEligibleSettingsExpirationRule, AdminEligibleSettingsJustificationRule, AdminEligibleSettingsActivationDayRule, AdminEligibleSettingsApprovalRule, AdminEligibleSettingsTicketingRule,
    UserMemberSettingsMfaRule, UserMemberSettingsExpirationRule, UserMemberSettingsJustificationRule, UserMemberSettingsActivationDayRule, UserMemberSettingsApprovalRule, UserMemberSettingsTicketingRule,
    UserEligibleSettingsMfaRule, UserEligibleSettingsExpirationRule, UserEligibleSettingsJustificationRule, UserEligibleSettingsActivationDayRule, UserEligibleSettingsApprovalRule, UserEligibleSettingsTicketingRule
    
}


#Update RoleSetting
function UpdateRoleSetting(){
    #List and Pick resource
    $resources = ListResources
    $resources | Format-Table -AutoSize -Wrap id, ResourceName, Type, ExternalId
    $res_choice = Read-Host "Pick an resource Id for assigment"
    $resourceId = $resources[$res_choice-1].ResourceId

    #List RoleSettings and Pick a role/multiple role to update
    $roleSettings = ListRoleSettings($resourceId)
    $roleSettings | Format-List id, RoleName, RoleDefinitionId, ResourceName, ResourceId, AdminMemberSettings, AdminEligibleSettings, UserMemberSettings, UserEligibleSettings,
    AdminMemberSettingsMfaRule, AdminMemberSettingsExpirationRule, AdminMemberSettingsJustificationRule, AdminMemberSettingsActivationDayRule, AdminMemberSettingsApprovalRule, AdminMemberSettingsTicketingRule,
    AdminEligibleSettingsMfaRule, AdminEligibleSettingsExpirationRule, AdminEligibleSettingsJustificationRule, AdminEligibleSettingsActivationDayRule, AdminEligibleSettingsApprovalRule, AdminEligibleSettingsTicketingRule,
    UserMemberSettingsMfaRule, UserMemberSettingsExpirationRule, UserMemberSettingsJustificationRule, UserMemberSettingsActivationDayRule, UserMemberSettingsApprovalRule, UserMemberSettingsTicketingRule,
    UserEligibleSettingsMfaRule, UserEligibleSettingsExpirationRule, UserEligibleSettingsJustificationRule, UserEligibleSettingsActivationDayRule, UserEligibleSettingsApprovalRule, UserEligibleSettingsTicketingRule
    
    $roleSettings | Format-Table -AutoSize -Wrap id, RoleName, ResourceName, RoleDefinitionId, ResourceId
    

    $roleSetting_choice = Read-Host "Pick a role Id"
    $roleSettingId = $roleSettings[$roleSetting_choice-1].RoleSettingId
    write-Host $roleSettingId
    

    # Activation Setting: "MfaRule", "ExpirationRule", "JustificationRule", "ActivationDayRule", "ApprovalRule", "TicketingRule"
    
    $Activation = Read-Host "Update Activation Setting or not (Y or N)"
    if ($Activation -like 'Y') 
    {
        $ActivationMfaRule = Read-Host "Activation MFA enabled (Y or N)"
        $ActivationExpirationRule = Read-Host "Activation Grant period in mins (ie. 240 is 4 hr)"
        $ActivationJustificationRule = Read-Host "Activation Justification enabled (Y or N)"
    
        $ActivationGP = [timespan]::fromminutes($ActivationExpirationRule)
        #$UserMemberSetting = '{@{ruleIdentifier=ExpirationRule; setting={"maximumGrantPeriod":"'+$ActivationGP+'","maximumGrantPeriodInMinutes":'+$ActivationExpirationRule+',"permanentAssignment":false}}'
        $UserMemberSetting =',"userMemberSettings": [{"ruleIdentifier":"ExpirationRule","setting": "{\"permanentAssignment\":false,\"maximumGrantPeriodInMinutes\":'+$ActivationExpirationRule+'}"}'
    

        if ($ActivationMfaRule -like 'Y') 
        {
            $UserMemberSetting = $UserMemberSetting + ',{"ruleIdentifier":"MfaRule","setting":"{\"mfaRequired\":true}"}'
        } elseif ($ActivationMfaRule -like 'N') 
        {
            $UserMemberSetting = $UserMemberSetting + ',{"ruleIdentifier":"MfaRule","setting":"{\"mfaRequired\":false}"}'
        }

        if ($ActivationJustificationRule -like 'Y') 
        {
            $UserMemberSetting = $UserMemberSetting + ',{"ruleIdentifier":"JustificationRule","setting":"{\"required\":true}"}]'
        } elseif ($ActivationJustificationRule -like 'N') 
        {
            $UserMemberSetting = $UserMemberSetting + ',{"ruleIdentifier":"JustificationRule","setting":"{\"required\":false}"}]'
        }

        Write-Host $UserMemberSetting
    }

    $AdminE = Read-Host "Update Admin Eligible Setting or not (Y or N)"
    if ($AdminE -like 'Y') 
    {
        $AdminEMfaRule = Read-Host "Admin Eligible MFA enabled (Y or N)"
        $AdminEExpirationRule = Read-Host "Admin Eligible Grant period in mins (ie. 240 is 4 hr)"
        $AdminEJustificationRule = Read-Host "Admin Eligible Justification enabled (Y or N)"
    
        $AdminEGP = [timespan]::fromminutes($AdminEExpirationRule)
        $AdminESetting =',"adminEligibleSettings": [{"ruleIdentifier":"ExpirationRule","setting": "{\"permanentAssignment\":false,\"maximumGrantPeriodInMinutes\":'+$AdminEExpirationRule+'}"}'
    

        if ($AdminEMfaRule -like 'Y') 
        {
            $AdminESetting = $AdminESetting + ',{"ruleIdentifier":"MfaRule","setting":"{\"mfaRequired\":true}"}'
        } elseif ($ActivationMfaRule -like 'N') 
        {
            $AdminESetting = $AdminESetting + ',{"ruleIdentifier":"MfaRule","setting":"{\"mfaRequired\":false}"}'
        }

        if ($AdminEJustificationRule -like 'Y') 
        {
            $AdminESetting = $AdminESetting + ',{"ruleIdentifier":"JustificationRule","setting":"{\"required\":true}"}]'
        } elseif ($ActivationJustificationRule -like 'N') 
        {
            $AdminESetting = $AdminESetting + ',{"ruleIdentifier":"JustificationRule","setting":"{\"required\":false}"}]'
        }

        Write-Host $AdminESetting
    }

    

    if (($AdminE -like 'Y') -or ($Activation -like 'Y'))
    {
        #foreach
        $SettingId = '{"id":"'+$roleSettingId+'"'
        Write-Host $SettingId
        $RoleSet = $SettingId+$UserMemberSetting+$AdminESetting+'}'
        Write-Host $RoleSet
        PatchRoleSetting $RoleSet $roleSettingId
    }
}


#Show menu
function ShowMenu(){
    Write-Host ""
    Write-Host "--------------------------------------- "
    Write-Host "Azure RBAC JIT - PowerShell Menu        "
    Write-Host "--------------------------------------- "
    Write-Host "  1.  EndUser List:             List your eligible role assignments"
    Write-Host "  2.  EndUser Activate:         Activate an eligible role"
    Write-Host "  3.  EndUser Deactivate:       Deactivate an active role"
    Write-Host "  4.  Admin List:               List Assignment against a resource"
    Write-Host "  5.  Admin Assign:             Assign a user to a role"
    Write-Host "  6.  Admin Delete:             Delete Assignment against a resource+role+user"
    Write-Host "  7.  Admin Extend:             List Expiring Eligible Assignment against a resource and option to extend"
    Write-Host "  8.  Admin/EndUser Cancel:     Cancel a request"
    Write-Host "  9.  Admin Query RoleSetting:  List roleSetting against a resource"
    Write-Host "  10. Admin Update RoleSetting: Choose RoleSetting to apply to a single or multiple roles"
    Write-Host "  11. Exit"
    Write-Host ""
}

############################################################################################################################################################################

$global:serviceRoot = "https://graph.microsoft.com/beta/privilegedAccess/azureResources/"
$global:MSGraphRoot = "https://graph.microsoft.com/v1.0/"
$global:headerParams = ""
$global:assigneeId = ""
$global:mfaDone = $false;
$global:expiration = '2019-07-01T00:00:00Z'
$global:authority = "https://login.microsoftonline.com/common"

$global:resourceAppIdURI = "https://graph.microsoft.com"
    

$clientID = "dabc52c4-106b-4179-9df2-2f791f44ba14"
$redirectUri = "https://pimmsgraph"
    

$loaded = Load-ActiveDirectoryAuthenticationLibrary
if ($loaded -eq $false)
{
    return
}

$Authed = AcquireToken $global:clientID $global:redirectUri $global:resourceAppIdURI $global:authority $false
if ($Authed -eq $false)
{
    return
}



do
{
    ShowMenu
    #Write-Host "Enter your selection"
    $input = Read-Host "Enter your selection"
    switch ($input)
    {
        '1'
        {
            $assignments = MyJitAssignments
            $assignments | Format-Table -AutoSize -Wrap id,RoleName,ResourceName,ResourceType,ExpirationDate
        }
        '2'
        {
            Activate
        }
        '3'
        {
            Deactivate
        }
        '4'
        {
            ListAssignment
        }
        '5'
        {
            AssignmentEligible
        }
        '6'
        {
            DelAssignment
        }
        '7'
        {
            ListExpiringEligibleAssignments
        }
        '8'
        {
            CancelRequest
        }
        '9'
        {
            ListRoleSetting
        }
        '10'
        {
            UpdateRoleSetting
        }
        '11'
        {
            return
        }

    }
}
until ($input -eq '11')

Write-Host ""
