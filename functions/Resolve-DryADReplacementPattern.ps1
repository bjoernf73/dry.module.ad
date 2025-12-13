<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

function Resolve-DryADReplacementPattern{
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [AllowEmptyString()]
        [string]$InputText,

        [Parameter(Position = 1, Mandatory)]
        [System.Collections.Generic.List[PSObject]]$Variables
    )
    
    foreach($Variable in $Variables){
        $Pattern = "###$($Variable.Name)###"
        if($InputText -match $Pattern){
            $Value = $Variable.Value 
            $InputText = $InputText -replace $Pattern, $Value
            olad d "Replacing '$Pattern' with '$Value'. Value after replacement: '$InputText'"
        }
    }
    return $InputText
}