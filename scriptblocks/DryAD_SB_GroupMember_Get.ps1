<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock] $DryAD_SB_GroupMember_Get ={
    param(
        $Group,
        $Member,
        $Server
    )
    try{
        $GetADGroupMemberParams = @{
            Identity    = $Group 
            Server      = $Server
            ErrorAction = 'Stop'
        }
        if((Get-ADGroupMember @GetADGroupMemberParams | Select-Object -Property Name).Name -Contains $Member){
            $true
        } 
        else{
            $false
        }
    }
    catch{
        $_
    }
}
