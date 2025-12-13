<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock]$DryAD_SB_PSModPath ={ 
    param(
        $Path,
        $PathRegEx
    )
    try{
        if($($ENV:PSModulePath) -notmatch "$PathRegEx"){
            $ENV:PSModulePath = "$($ENV:PSModulePath);$Path"
        }
        return "$($ENV:PSModulePath)"
    }
    catch{
        # just ignore, we will test the output instead
    }
}
