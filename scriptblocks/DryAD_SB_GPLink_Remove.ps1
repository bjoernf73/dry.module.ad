<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock]$DryAD_SB_GPLink_Remove ={
    param(
        $OU,
        $LinkToRemove,
        $Server
    ) 
    
    $Status = $false
    $ErrorString = ''
    try{
        $RemoveLinkParams = @{
            Name        = $LinkToRemove
            Target      = $OU
            ErrorAction = 'Stop'
            Server      = $Server
        }
        Remove-GPLink @RemoveLinkParams | Out-Null
        $Status = $true
        return @($Status, $ErrorString)
    }
    catch{
        $ErrorString = $_.ToString()
        @($Status, $ErrorString)
    }
}
