<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock] $DryAD_SB_RemoveAndRecreateDir ={
    param(
        $Path
    )
    try{
        if(Test-Path -Path $Path -ErrorAction Ignore){
            $RemoveItemParams = @{
                Path        = "$Path*" 
                Recurse     = $true
                Force       = $true
                Confirm     = $false 
                ErrorAction = 'Stop'
            }
            Remove-Item @RemoveItemParams
        }
        $NewItemParams = @{
            Path        = $Path 
            ItemType    = 'Directory' 
            Force       = $true
            ErrorAction = 'Stop'
        }
        New-Item @NewItemParams | Out-Null
        $true
    }
    catch{
        $_
    }
    finally{
        @('RemoveItemParams', 'NewItemParams').foreach({
            Remove-Variable -Name $_ -ErrorAction Ignore | Out-Null
        }) 
    }
}
