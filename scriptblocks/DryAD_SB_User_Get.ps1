<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock]$DryAD_SB_User_Get ={
    param(
        $Name,
        $Server
    ) 
    try{
        Get-ADUser -Identity $Name -Server $Server | Out-Null
        $true
    }
    catch{
        if($_.CategoryInfo.Reason -eq 'ADIdentityNotFoundException'){
            # The Object does not exist
            $false
        }
        else{
            $_
        }
    }
}
