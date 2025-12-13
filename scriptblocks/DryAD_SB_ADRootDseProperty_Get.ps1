<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock]$DryAD_SB_ADRootDseProperty_Get ={
    param(
        $Property,
        $Server
    ) 
    try{
        (Get-ADRootDSE -Server $Server -ErrorAction Stop)."$Property"
    }
    catch{
        $_
    }
}
