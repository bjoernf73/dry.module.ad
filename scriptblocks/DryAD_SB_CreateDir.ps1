<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock] $DryAD_SB_CreateDir ={
    param(
        $Directory
    )
    try{
        if(-not (Test-Path -Path $Directory -ErrorAction Ignore)){
            New-Item -Path $Directory -ItemType Directory -Force -ErrorAction Stop |
                Out-Null
        }
        $true
    }
    catch{
        $_
    }
}
