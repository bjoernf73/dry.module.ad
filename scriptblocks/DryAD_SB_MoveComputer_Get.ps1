<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock] $DryAD_SB_MoveComputer_Get ={ 
    param(
        [string]
        $ComputerName,

        [string]
        $TargetOU,
        
        [string]
        $Server
    ) 
    
    try{
        [string]$DomainDN = (Get-ADDomain -Server $Server -ErrorAction Stop | 
                Select-Object -Property distinguishedName).distinguishedName
        
        if($TargetOU -notmatch "$DomainDN$"){
            $TargetOU = $TargetOU + ",$DomainDN"
        }
        $TargetComputerDN = "CN=$ComputerName,$TargetOU"

        $GetADComputerParams = @{
            Server   = $Server
            Identity = $ComputerName
        }
        if((Get-ADComputer @GetADComputerParams | Select-Object -Property distinguishedName).distinguishedName -eq "$TargetComputerDN"){
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
