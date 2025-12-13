<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock] $DryAD_SB_MoveComputer_Set ={
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
        
        $GetADComputerParams = @{
            Identity    = $ComputerName
            Server      = $Server 
            ErrorAction = 'Stop'
        }
        $TargetComputer = Get-ADComputer @GetADComputerParams

        $MoveADObjectParams = @{
            TargetPath  = $TargetOU
            Server      = $Server 
            ErrorAction = 'Stop'
        }
        $TargetComputer | 
            Move-ADObject @MoveADObjectParams
        $true
    }
    catch{
        $_
    }
}
