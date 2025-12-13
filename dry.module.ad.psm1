Using Namespace System.Management.Automation.Runspaces
<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

# Dot source all ScriptBlock-scripts, Function-scripts, Classes-scripts
# and ExportedFunction-scripts
$ScriptBlocksPath      = "$PSScriptRoot\scriptblocks\*.ps1"
$FunctionsPath         = "$PSScriptRoot\functions\*.ps1"
$ClassesPath           = "$PSScriptRoot\classes\*.ps1"
$ExportedFunctionsPath = "$PSScriptRoot\xfunctions\*.ps1"

$ScriptBlocks          = Resolve-Path -Path $ScriptBlocksPath -ErrorAction Stop
$Functions             = Resolve-Path -Path $FunctionsPath -ErrorAction Stop
$Classes               = Resolve-Path -Path $ClassesPath -ErrorAction Stop
$ExportedFunctions     = Resolve-Path -Path $ExportedFunctionsPath -ErrorAction Stop

foreach($ScriptBlock in $ScriptBlocks){
    . $ScriptBlock.Path
}
foreach($function in $Functions){
    . $Function.Path
}
foreach($Class in $Classes){
    . $Class.Path
}
foreach($Exportedfunction in $ExportedFunctions){
    . $ExportedFunction.Path
}

# ensure the helper modules are in $env:psmodulepath
$modulePath = Join-Path -Path $PSScriptRoot -child 'helpers'
if(-not ($env:PSModulePath -split ";" | ForEach-Object{ $_.Trim() } | Where-Object{ $_ -ieq $modulePath })){
    $env:PSModulePath += ";$modulePath"
} 