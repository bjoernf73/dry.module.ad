<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock] $DryAD_SB_GroupMember_Set ={ 
    param(
        $Group,
        $Member,
        $Server
    ) 
    try{
        $AddADGroupMemberParams = @{
            Identity    = $Group 
            Members     = $Member 
            Server      = $Server 
            ErrorAction = 'Stop'
        }
        Add-ADGroupMember @AddADGroupMemberParams | Out-Null
        $true
    }
    catch{
        $_
    }
}

