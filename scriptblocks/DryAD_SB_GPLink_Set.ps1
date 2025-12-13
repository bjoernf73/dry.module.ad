<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock]$DryAD_SB_GPLink_Set ={
    param(
        $OU,
        $GPO,
        $Order,
        $LinkEnabled,
        $Enforced,
        $DomainController
    ) 
    
    $Status = $false
    $ErrorString = ''
    try{
        $SetLinkParams = @{
            Name        = $GPO
            Target      = $OU
            Order       = $Order
            LinkEnabled = $LinkEnabled
            Enforced    = $Enforced
            ErrorAction = 'Stop'
            Server      = $DomainController
        }
        Set-GPLink @SetLinkParams | Out-Null
        $Status = $true
        return @($Status, $ErrorString)
    }
    catch{
        # If caught, get the string
        $ErrorString = $_.ToString()
        return @($Status, $ErrorString)
    }
}
