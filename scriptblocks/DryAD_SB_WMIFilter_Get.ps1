<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock]$DryAD_SB_WMIFilter_Get ={
    param(
        $Name,
        $Server
    ) 
    try{
        $ADRootDSE = Get-ADRootDSE -Server $Server -ErrorAction Stop
        $DomainDN = $ADRootDSE.DefaultNamingContext
        $WMIPath = ("CN=SOM,CN=WMIPolicy,CN=System,$DomainDN")
        $GetADObjectParams = @{
            Filter      = "msWMI-name -eq '$Name'"
            SearchBase  = $WMIPath
            Properties  = 'msWMI-name'
            Server      = $Server
            ErrorAction = 'Stop'
        }
        if(Get-ADObject @GetADObjectParams ){
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
