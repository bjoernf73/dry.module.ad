<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock]$DryAD_SB_RemoveItem ={
    param(
        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter()]
        [System.Management.Automation.ActionPreference]
        $ErrorAction = 'Stop'
    )
    try{
        Remove-Item -Path $Path -Confirm:$false -ErrorAction $ErrorAction
    }
    catch{
        $_
    }
}
