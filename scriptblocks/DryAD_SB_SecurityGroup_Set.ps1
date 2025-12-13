<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock] $DryAD_SB_SecurityGroup_Set ={ 
    param(
        $Name,
        $Path,
        $Description,
        $GroupCategory,
        $GroupScope,
        $Server
    )

    $ADRootDSE = Get-ADRootDSE 
    $DomainDN = $ADRootDSE.DefaultNamingContext
    
    # Add DomainDN to path if not already added
    if($Path -notmatch "$DomainDN$"){
        $Path = $Path + ",$DomainDN"
    }
    
    try{
        $NewADGroupParams = @{
            Name          = $Name 
            Path          = $Path 
            Description   = $Description 
            GroupCategory = $GroupCategory
            GroupScope    = $GroupScope
            Server        = $Server
            ErrorAction   = 'Stop'
        }
        New-ADGroup @NewADGroupParams | Out-Null
        $true
    }
    catch{
        $_
    }
}
