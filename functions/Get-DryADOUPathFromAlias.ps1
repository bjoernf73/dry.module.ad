<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>
function Get-DryADOUPathFromAlias{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Alias,

        [Parameter(Mandatory)]
        [array]$OUs
    )

    $ReferencedOU = $OUs | Where-Object{  
        $_.Alias -eq $Alias
    }
    olad d 'Alias', "$Alias"

    if($null -eq $ReferencedOU){
        olad e @('Unable to resolve OU from Alias', 'No OUs found')
        throw "Unable to find OU for Alias '$Alias': No references found"
    } 

    if($ReferencedOU -is [array]){
        olad e @('Unable to resolve OU from Alias', 'Multiple OUs found')
        throw "Unable to find single OU for Alias '$Alias': Multiple references found"
    }
    
    $Path = $ReferencedOU.Path
    if($null -eq $Path){
        olad e "Found OU '$($OU.Alias)', but it contains no path"
        throw "Found OU '$($OU.Alias)', but it contains no path"
    }

    olad v @("Alias '$Alias'", "$Path")
    $Path
}
