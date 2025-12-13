<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock]$DryAD_SB_GPLink_Get ={
    param(
        $OU,
        $DomainController
    ) 
    $CurrentLinks = @()
    $ErrorString = ''
    try{
        [array]$CurrentLinks = ((Get-GPInheritance -Target $OU -Server $DomainController).gpolinks | Select-Object -Property DisplayName).DisplayName
        return @($CurrentLinks, $ErrorString)
    }
    catch{
        # If caught, get the string
        $ErrorString = $_.ToString()
        return @($CurrentLinks, $ErrorString)
    }
}
